module Commands
  class Prod < Base
    def apply
      infra
      kube
    end

    def infra
      run_terraform(terraform_infra)
      run_ansible(ansible_command('registry'))
    end

    def kube
      run_terraform(terraform_ingress)
      run_terraform(terraform_dns)
      run_ansible(ansible_command('kube'))
    end

    def destroy
      run_terraform(terraform_destroy)
    end

    private

    def terraform_infra
      [
        @terraform_runner.init,
        @terraform_runner.apply(target: 'infra'),
        @terraform_runner.output_raw,
        @terraform_runner.output
      ]
    end

    def terraform_ingress
      [
        @terraform_runner.apply(target: 'ingress')
      ]
    end

    def terraform_dns
      [
        @terraform_runner.apply(target: 'dns')
      ]
    end

    def terraform_destroy
      [
        @terraform_runner.apply(target: 'dns'),
        @terraform_runner.apply(target: 'ingress'),
        @terraform_runner.apply(target: 'infra')
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
