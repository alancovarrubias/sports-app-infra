module Commands
  class Prod < Base
    def apply
      run_terraform(terraform_infra)
      run_ansible(ansible_infra)
      run_terraform(terraform_kube)
      run_ansible(ansible_kube)
    end

    def infra
      run_ansible(ansible_command('infra'))
    end

    def kube
      run_ansible(ansible_command('k8s'))
    end

    def destroy
      run_terraform(terraform_destroy)
    end

    private

    def terraform_infra
      [
        @terraform_runner.init,
        @terraform_runner.apply(target: 'module.infra'),
        @terraform_runner.output_raw,
        @terraform_runner.output
      ]
    end

    def terraform_kube
      [
        @terraform_runner.apply(target: 'module.k8s')
      ]
    end

    def terraform_destroy
      [
        @terraform_runner.apply(target: 'module.k8s'),
        @terraform_runner.apply(target: 'module.infra')
      ]
    end

    def ansible_command(tags)
      @ansible_runner.command(
        playbook: 'setup_prod',
        variables: variables,
        tags: tags,
        env: @options[:module]
      )
    end

    def variables
      {
        secret_key_base: secret_key_base,
        cache_url: outputs['cache_uri']['value'],
        database_url: outputs['database_uri']['value'],
        registry_name: outputs['registry_name']['value'],
        kubeconfig: KUBECONFIG
      }
    end

    def secret_key_base
      `ruby -rsecurerandom -e 'puts SecureRandom.hex(64)'`.chomp
    end
  end
end
