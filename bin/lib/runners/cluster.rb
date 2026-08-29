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

    # Forces already-running pods to re-pull the image just pushed by
    # #registry. imagePullPolicy: Always means kubelet WILL check the
    # registry again, but only on pod restart -- pushing a new image
    # under the same tag doesn't trigger that by itself. No-op on a
    # fresh cluster, since #kube hasn't created any deployments yet.
    def restart
      running = running_deployments & DEPLOYMENTS
      return if running.empty?

      run_commands(nil, @kubectl_command.build(running))
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
      targets += ['destroy_registry', 'destroy_infra', 'output']
      run_terraform(*targets)
    end

    private

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
