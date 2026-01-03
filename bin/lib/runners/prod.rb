module Runners
  class Prod < Base
    def apply
      infra
      registry
      ingress
      dns
      kube
    end

    def apply_base
      infra
      registry
      ingress
      kube
    end

    def infra
      run_terraform(
        'init',
        'apply_infra',
        'kubeconfig',
        'output'
      )
    end

    def registry
      run_terraform(
        'apply_registry'
      )
      ansible_command('registry')
    end

    def ingress
      run_terraform(
        'apply_ingress'
      )
    end

    def dns
      run_terraform(
        'apply_dns'
      )
    end

    def kube
      ansible_command('kube')
    end

    def destroy
      run_terraform(
        'destroy_dns',
        'destroy_ingress',
        'destroy_registry',
        'destroy_infra',
        'output'
      )
    end

    def destroy_base
      run_terraform(
        'destroy_ingress',
        'destroy_infra',
        'output'
      )
    end

    private

    def ansible_command(tags)
      run_ansible(
        playbook: 'setup_prod',
        variables: ansible_variables,
        tags: tags,
        env: @options[:module]
      )
    end

    def ansible_variables
      {
        secret_key_base: `ruby -rsecurerandom -e 'puts SecureRandom.hex(64)'`.chomp,
        cache_url: outputs['cache_uri']['value'],
        database_url: outputs['database_uri']['value'],
        registry_name: outputs['registry_name']['value'],
        kubeconfig: KUBECONFIG
      }
    end
  end
end
