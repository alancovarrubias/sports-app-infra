module Commands
  class Prod < Base
    def apply
      infra
      registry
      kube
    end

    def infra
      run_terraform(
        @terraform_runner.init,
        @terraform_runner.apply('infra'),
        @terraform_runner.output_raw,
        @terraform_runner.output
      )
    end

    def registry
      run_terraform(
        @terraform_runner.apply('registry')
      )
      run_ansible(ansible_command('registry'))
    end

    def kube
      run_terraform(
        @terraform_runner.apply('ingress')
      )
      run_terraform(
        @terraform_runner.apply('dns')
      )
      run_ansible(ansible_command('kube'))
    end

    def destroy
      run_terraform(
        @terraform_runner.destroy('dns'),
        @terraform_runner.destroy('ingress'),
        @terraform_runner.destroy('registry'),
        @terraform_runner.destroy('infra')
      )
    end

    def destroy_infra
      run_terraform(
        @terraform_runner.destroy('dns'),
        @terraform_runner.destroy('ingress'),
        @terraform_runner.destroy('infra')
      )
    end

    private

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
