require 'securerandom'
require 'uri'
require 'fileutils'

module Runners
  # Shared shape for environments backed by a DigitalOcean Kubernetes
  # cluster (Stage, Prod): infra, then registry, then ingress, then
  # (optionally) DNS, then the app itself via Ansible.
  class Cluster < Base
    DEPLOYMENTS = %w[client server auth football crawler sidekiq].freeze
    DB_CONTAINERS = %w[auth football].freeze

    def initialize(options)
      super
      @kubectl_command = Commands::Kubectl.new
    end

    def apply
      infra
      registry
      ingress
      dns if dns?
      kube
      restore_databases
    end

    def infra
      run_terraform('init', 'apply_infra', 'kubeconfig', 'output')
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
      db = @options[:database]
      abort("No database specified -- pass -d <#{DB_CONTAINERS.join('|')}>") if db.nil?
      unless DB_CONTAINERS.include?(db)
        abort("Unknown database '#{db}' -- expected one of #{DB_CONTAINERS.join(', ')}")
      end

      pod = pod_name(db)
      abort("No running #{db} pod found -- is #{@options[:env]} deployed?") if pod.empty?

      run_commands(@kubectl_command.exec(pod, 'rails', 'console'))
    end

    def ingress
      run_terraform('apply_ingress', 'output')
    end

    def dns
      run_terraform('apply_dns', 'output')
    end

    def kube
      ansible_command('kube')
    end

    def destroy
      dump_databases
      targets = ['destroy_ingress']
      targets << 'destroy_dns' if dns?
      targets += %w[destroy_registry destroy_infra output]
      run_terraform(*targets)
    end

    private

    def dump_databases
      DB_CONTAINERS.each { |db| dump_database(db) }
    end

    def dump_database(db)
      FileUtils.mkdir_p(dump_dir)
      run_commands(%(#{pg_bin('pg_dump')} "#{database_uri(db)}" --data-only --no-owner -f #{dump_file(db)}))
    end

    def restore_databases
      DB_CONTAINERS.each { |db| restore_database(db) }
    end

    def restore_database(db)
      return unless File.exist?(dump_file(db))

      run_commands(%(#{pg_bin('psql')} "#{database_uri(db)}" -f #{dump_file(db)}))
    end

    def pg_bin(command)
      "$(brew --prefix postgresql@18)/bin/#{command}"
    end

    def database_uri(db)
      uri = URI.parse(outputs['database_uri']['value'])
      uri.path = "/#{db}_production"
      uri.to_s
    end

    def dump_dir
      File.join(ROOT_DIR, 'bin/outputs/dumps', @options[:env])
    end

    def dump_file(db)
      File.join(dump_dir, "#{db}.sql")
    end

    def pod_name(app)
      `kubectl --kubeconfig=#{KUBECONFIG} get pods -l app=#{app} -o jsonpath='{.items[0].metadata.name}'`.strip
    end

    def running_deployments
      `kubectl --kubeconfig=#{KUBECONFIG} get deployments -o jsonpath='{.items[*].metadata.name}'`.split
    end

    def dns?
      false
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
      {
        secret_key_base: SecureRandom.hex(64),
        cache_url: outputs['cache_uri']['value'],
        database_url: outputs['database_uri']['value'],
        auth_database_url: database_uri('auth'),
        football_database_url: database_uri('football'),
        registry_name: outputs['registry_name']['value'],
        kubeconfig: KUBECONFIG
      }
    end
  end
end
