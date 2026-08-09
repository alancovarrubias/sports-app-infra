module Runners
  class Stage < Base
    def apply
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
        'apply_registry',
        'output'
      )
      ansible_command('registry')
    end

    def ingress
      run_terraform(
        'apply_ingress',
        'output'
      )
    end

    def kube
      ansible_command('kube')
    end

    def destroy
      run_terraform(
        'destroy_ingress',
        'destroy_registry',
        'destroy_infra',
        'output'
      )
    end

    private

    def ansible_command(tags)
      run_ansible(
        playbook: 'setup_stage',
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
        kubeconfig: KUBECONFIG,
        domain_name: 'sports-app.test'
      }
    end
  end
end
