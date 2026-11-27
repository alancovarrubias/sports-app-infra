require 'securerandom'
require 'uri'

module Runners
  # Environments backed by a DigitalOcean Kubernetes cluster (stage, prod):
  # infra, then registry, then ingress, then Datadog log shipping, then
  # (prod only) DNS, then the app itself via Ansible. Prod is the only
  # environment with its own domain, so it's the only one that touches DNS
  # or needs apply_base/destroy_base to rebuild everything except it.
  class Cluster < Base
    DEPLOYMENTS = %w[client server auth football crawler sidekiq nba nba-sidekiq mlb mlb-sidekiq].freeze
    # sidekiq/nba-sidekiq/mlb-sidekiq have no image of their own -- each runs
    # its web counterpart's image, so none of them is ever pushed.
    REGISTRY_CONTAINERS = (DEPLOYMENTS - %w[sidekiq nba-sidekiq mlb-sidekiq]).freeze
    # nba and mlb's Sidekiq workers share the same Valkey cluster as football
    # (and each other) via DO-managed Redis/Valkey's 16 logical databases --
    # football is grandfathered on the unindexed default (db 0).
    NBA_REDIS_DB = 1
    MLB_REDIS_DB = 2
    STAGE_DOMAIN_NAME = 'sports-app.test'.freeze
    HELM_APPLY_ATTEMPTS = 3
    HELM_APPLY_RETRY_DELAY = 15

    def initialize(options)
      super
      @kubectl_command = Commands::Kubectl.new
      @database_command = Commands::Database.new(options)
      @mongo_command = Commands::Mongo.new(options)
    end

    def apply
      infra
      registry
      ingress
      datadog
      dns if prod?
      kube
      @database_command.restore_all(outputs['database_uri']['value'])
      @mongo_command.restore_all(outputs['mongo_uri']['value'])
    end

    def apply_base
      infra
      registry
      ingress
      datadog
      kube
    end

    def destroy
      @database_command.dump_all(outputs['database_uri']['value'])
      @mongo_command.dump_all(outputs['mongo_uri']['value'])
      targets = ['destroy_ingress']
      targets << 'destroy_dns' if prod?
      targets += %w[destroy_datadog destroy_registry destroy_infra output]
      run_terraform(*targets)
    end

    def destroy_base
      run_terraform('destroy_ingress', 'destroy_infra', 'output')
    end

    def infra
      run_terraform('init', 'apply_infra', 'kubeconfig', 'output')
      run_commands(@kubectl_command.wait_for_nodes)
    end

    def registry
      validate_service!
      run_terraform('apply_registry', 'output')
      ansible_command('registry')
      restart
    end

    def restart
      validate_service!
      running = running_deployments & DEPLOYMENTS
      running &= restart_targets if @options[:service]
      return if running.empty?

      run_commands(@kubectl_command.restart(running))
    end

    def console
      run_commands(@kubectl_command.exec(target_pod, 'rails', 'console'))
    end

    def seed
      run_commands(@kubectl_command.exec(target_pod, 'rails', 'runner', %("load Rails.root.join('db/seeds.rb')")))
    end

    # Seeds the first Backfill Task for every independent starting point in
    # the target backend (-d football/nba/mlb) -- each job then fans out the
    # rest of its own chain, so this is the only dispatch step that needs
    # driving from outside the cluster. See the sports-backfill wayfinder
    # map (sports-app repo, ticket 08) for the full design.
    def backfill_seed
      run_commands(@kubectl_command.exec(target_pod, 'bundle', 'exec', 'rake', 'backfill:seed'))
    end

    def dump
      @database_command.dump(outputs['database_uri']['value'], @options[:database])
    end

    def restore
      @database_command.restore(outputs['database_uri']['value'], @options[:database])
    end

    def ingress
      with_retries(HELM_APPLY_ATTEMPTS) { run_terraform('apply_ingress', 'output') }
    end

    def datadog
      with_retries(HELM_APPLY_ATTEMPTS) { run_terraform('apply_datadog', 'output') }
    end

    def dns
      run_terraform('apply_dns', 'output')
    end

    def kube
      ansible_command('kube')
    end

    private

    # The Helm/Kubernetes Terraform providers make one connection attempt and
    # give up on it, unlike kubectl's own built-in watch/retry loop -- so a
    # freshly created cluster's API server can still be intermittently
    # unreachable (EOF) for a short window after `infra` returns, even though
    # its nodes are already Ready. Retrying the apply rides out that window.
    # Wraps every helm_release-backed step (ingress, datadog) for this reason.
    def with_retries(attempts)
      yield
    rescue SystemExit
      raise if attempts <= 1

      puts "Transient failure -- retrying (#{attempts - 1} attempt(s) left)..."
      sleep HELM_APPLY_RETRY_DELAY
      with_retries(attempts - 1) { yield }
    end

    def target_pod
      db = @database_command.validate!(@options[:database])
      pod = pod_name(db)
      abort("No running #{db} pod found -- is #{@options[:env]} deployed?") if pod.empty?

      pod
    end

    def prod?
      @options[:env] == 'prod'
    end

    def validate_service!
      return unless @options[:service]
      return if DEPLOYMENTS.include?(@options[:service])

      abort("Unknown service '#{@options[:service]}' -- expected one of #{DEPLOYMENTS.join(', ')}")
    end

    def registry_containers
      REGISTRY_CONTAINERS.include?(@options[:service]) ? [@options[:service]] : []
    end

    # Each web service's Sidekiq worker runs its web counterpart's image
    # rather than its own, so restarting the web service must carry its
    # worker along or it keeps running the old code.
    def restart_targets
      return %w[football sidekiq] if @options[:service] == 'football'
      return %w[nba nba-sidekiq] if @options[:service] == 'nba'
      return %w[mlb mlb-sidekiq] if @options[:service] == 'mlb'

      [@options[:service]]
    end

    def pod_name(app)
      `kubectl --kubeconfig=#{KUBECONFIG} get pods -l app=#{app} -o jsonpath='{.items[0].metadata.name}'`.strip
    end

    def running_deployments
      `kubectl --kubeconfig=#{KUBECONFIG} get deployments -o jsonpath='{.items[*].metadata.name}'`.split
    end

    def playbook
      "setup_#{@options[:env]}"
    end

    def ansible_command(tags)
      run_ansible(
        playbook: playbook,
        variables: ansible_variables,
        tags: tags,
        env: @options[:env]
      )
    end

    def ansible_variables
      base_uri = outputs['database_uri']['value']
      cache_uri = outputs['cache_uri']['value']

      variables = {
        secret_key_base: SecureRandom.hex(64),
        cache_url: cache_uri,
        mongo_url: outputs['mongo_uri']['value'],
        database_url: base_uri,
        auth_database_url: @database_command.uri(base_uri, 'auth'),
        football_database_url: @database_command.uri(base_uri, 'football'),
        nba_database_url: @database_command.uri(base_uri, 'nba'),
        mlb_database_url: @database_command.uri(base_uri, 'mlb'),
        nba_redis_url: redis_uri(cache_uri, NBA_REDIS_DB),
        mlb_redis_url: redis_uri(cache_uri, MLB_REDIS_DB),
        registry_name: outputs['registry_name']['value'],
        kubeconfig: KUBECONFIG
      }
      variables[:registry_containers] = registry_containers if @options[:service]
      return variables if prod?

      variables.merge(domain_name: STAGE_DOMAIN_NAME, local_image_tag: 'prod')
    end

    # Points a Valkey URI at a specific logical database (DO-managed
    # Redis/Valkey supports the same 16-database SELECT every Redis does),
    # mirroring how each backend already gets its own dedicated database.
    def redis_uri(base_uri, index)
      parsed = URI.parse(base_uri)
      parsed.path = "/#{index}"
      parsed.to_s
    end
  end
end
