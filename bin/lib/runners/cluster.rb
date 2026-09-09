require 'securerandom'

module Runners
  # Shared shape for environments backed by a DigitalOcean Kubernetes
  # cluster (Stage, Prod): infra, then registry, then ingress, then
  # (optionally) DNS, then the app itself via Ansible.
  class Cluster < Base
    DEPLOYMENTS = %w[client server auth football crawler sidekiq].freeze

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

    def console_auth
      console('auth')
    end

    def console_football
      console('football')
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
      targets = ['destroy_ingress']
      targets << 'destroy_dns' if dns?
      targets += %w[destroy_registry destroy_infra output]
      run_terraform(*targets)
    end

    private

    def console(app)
      pod = pod_name(app)
      abort("No running #{app} pod found -- is #{@options[:env]} deployed?") if pod.empty?

      run_commands(@kubectl_command.exec(pod, 'rails', 'console'))
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
        registry_name: outputs['registry_name']['value'],
        kubeconfig: KUBECONFIG
      }
    end
  end
end
