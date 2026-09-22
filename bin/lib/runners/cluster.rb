require 'securerandom'

module Runners
  # Environments backed by a DigitalOcean Kubernetes cluster (stage, prod):
  # infra, then registry, then ingress, then (prod only) DNS, then the app
  # itself via Ansible. Prod is the only environment with its own domain, so
  # it's the only one that touches DNS or needs apply_base/destroy_base to
  # rebuild everything except it.
  class Cluster < Base
    DEPLOYMENTS = %w[client server auth football crawler sidekiq].freeze
    STAGE_DOMAIN_NAME = 'sports-app.test'.freeze
    INGRESS_APPLY_ATTEMPTS = 3
    INGRESS_APPLY_RETRY_DELAY = 15

    def initialize(options)
      super
      @kubectl_command = Commands::Kubectl.new
      @database_command = Commands::Database.new(options)
    end

    def apply
      infra
      registry
      ingress
      dns if prod?
      kube
      @database_command.restore_all(outputs['database_uri']['value'])
    end

    def apply_base
      infra
      registry
      ingress
      kube
    end

    def destroy
      @database_command.dump_all(outputs['database_uri']['value'])
      targets = ['destroy_ingress']
      targets << 'destroy_dns' if prod?
      targets += %w[destroy_registry destroy_infra output]
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
      run_terraform('apply_registry', 'output')
      ansible_command('registry')
      restart
    end

    def restart
      running = running_deployments & DEPLOYMENTS
      return if running.empty?

      run_commands(@kubectl_command.restart(running))
    end

    def console
      run_commands(@kubectl_command.exec(target_pod, 'rails', 'console'))
    end

    def seed
      run_commands(@kubectl_command.exec(target_pod, 'rails', 'runner', %("load Rails.root.join('db/seeds.rb')")))
    end

    def dump
      @database_command.dump(outputs['database_uri']['value'], @options[:database])
    end

    def restore
      @database_command.restore(outputs['database_uri']['value'], @options[:database])
    end

    def ingress
      with_retries(INGRESS_APPLY_ATTEMPTS) { run_terraform('apply_ingress', 'output') }
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
    def with_retries(attempts)
      yield
    rescue SystemExit
      raise if attempts <= 1

      puts "Transient failure -- retrying (#{attempts - 1} attempt(s) left)..."
      sleep INGRESS_APPLY_RETRY_DELAY
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

      variables = {
        secret_key_base: SecureRandom.hex(64),
        cache_url: outputs['cache_uri']['value'],
        mongo_url: outputs['mongo_uri']['value'],
        database_url: base_uri,
        auth_database_url: @database_command.uri(base_uri, 'auth'),
        football_database_url: @database_command.uri(base_uri, 'football'),
        registry_name: outputs['registry_name']['value'],
        kubeconfig: KUBECONFIG
      }
      return variables if prod?

      variables.merge(domain_name: STAGE_DOMAIN_NAME, local_image_tag: 'prod')
    end
  end
end
