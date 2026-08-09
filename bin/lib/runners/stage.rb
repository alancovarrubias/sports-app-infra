module Runners
  class Stage < Base
    def apply
      infra
      registry
      ingress
      kube
      update_hosts
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

    def kube
      ansible_command('kube')
    end

    def update_hosts
      ip = outputs['ingress_ip']['value'] rescue nil
      return unless ip

      puts "\n" + "=" * 60
      puts "STAGE DEPLOYMENT COMPLETE"
      puts "=" * 60
      puts "\nTo access your app, run:"
      puts "  sudo sed -i '' '/sports-app.test/d' /etc/hosts"
      puts "  echo '#{ip} sports-app.test' | sudo tee -a /etc/hosts"
      puts "\nThen visit: http://sports-app.test"
      puts "=" * 60 + "\n"
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
