RSpec.describe 'Cluster-family Runners' do
  shared_examples 'a Cluster Runner' do
    subject(:runner) { described_class.new(options) }

    let(:options) { { env: env_name, tags: nil, output_file: "/tmp/#{env_name}-cluster-spec.json" } }
    let(:fake_secret) { 'f' * 128 }
    let(:fake_outputs) do
      {
        'cache_uri' => { 'value' => 'redis://fake-cache' },
        'database_uri' => { 'value' => 'postgres://fake-db' },
        'registry_name' => { 'value' => 'registry.digitalocean.com/fake' }
      }
    end

    before do
      stub_system!
      allow(SecureRandom).to receive(:hex).with(64).and_return(fake_secret)
      allow(runner).to receive(:outputs).and_return(fake_outputs)
      allow(runner).to receive(:running_deployments).and_return([])
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(/bin\/outputs\/dumps/).and_return(false)
    end

    def dump(db)
      "$(brew --prefix postgresql@18)/bin/pg_dump \"postgres://fake-db/#{db}_production\" --data-only --no-owner " \
        "-f #{Constants::ROOT_DIR}/bin/outputs/dumps/#{env_name}/#{db}.sql"
    end

    def restore(db)
      "$(brew --prefix postgresql@18)/bin/psql \"postgres://fake-db/#{db}_production\" " \
        "-f #{Constants::ROOT_DIR}/bin/outputs/dumps/#{env_name}/#{db}.sql"
    end

    def terraform(*rest)
      "terraform -chdir=#{env_name} #{rest.join(' ')}"
    end

    def ansible(tags)
      base = "ansible-playbook -e @extra_vars.yml -e @custom_vars.yml --tags #{tags} -e env=#{env_name} " \
             "-e secret_key_base=#{fake_secret} -e cache_url=redis://fake-cache -e database_url=postgres://fake-db " \
             "-e registry_name=registry.digitalocean.com/fake -e kubeconfig=#{Constants::KUBECONFIG}"
      "#{base}#{extra_ansible_variables} setup_#{env_name}.yml"
    end

    describe '#infra' do
      it 'applies the infra Terraform module, pulls kubeconfig, then refreshes outputs' do
        runner.infra
        expect(captured_commands).to eq([
          terraform('init'),
          terraform('apply -target=module.infra -var-file=../terraform.tfvars --auto-approve'),
          terraform("output -raw kubeconfig > #{Constants::KUBECONFIG}"),
          terraform("output -json > #{options[:output_file]}")
        ])
      end
    end

    describe '#registry' do
      it 'applies the registry module, refreshes outputs, then configures it over Ansible' do
        runner.registry
        expect(captured_commands).to eq([
          terraform('apply -target=module.registry -var-file=../terraform.tfvars --auto-approve'),
          terraform("output -json > #{options[:output_file]}"),
          ansible('registry')
        ])
      end

      it 'also restarts already-running deployments so they pick up the freshly pushed image' do
        allow(runner).to receive(:running_deployments).and_return(['client'])
        runner.registry
        expect(captured_commands.last).to eq("kubectl --kubeconfig=#{Constants::KUBECONFIG} rollout restart deployment/client")
      end
    end

    describe '#restart' do
      it 'restarts only the deployments that are both running and known to this app' do
        allow(runner).to receive(:running_deployments).and_return(%w[client server unrelated-thing])
        runner.restart
        expect(captured_commands).to eq([
          "kubectl --kubeconfig=#{Constants::KUBECONFIG} rollout restart deployment/client deployment/server"
        ])
      end

      it 'does nothing on a fresh cluster, where no deployments exist yet' do
        allow(runner).to receive(:running_deployments).and_return([])
        runner.restart
        expect(captured_commands).to eq([])
      end
    end

    describe '#console_auth' do
      it 'execs a rails console into the running auth pod' do
        allow(runner).to receive(:pod_name).with('auth').and_return('auth-6bf9797b6c-b4484')
        runner.console_auth
        expect(captured_commands).to eq([
          "kubectl --kubeconfig=#{Constants::KUBECONFIG} exec -it auth-6bf9797b6c-b4484 -- rails console"
        ])
      end

      it 'aborts with a clear message when no auth pod is running' do
        allow(runner).to receive(:pod_name).with('auth').and_return('')
        expect { runner.console_auth }.to raise_error(SystemExit)
        expect(captured_commands).to eq([])
      end
    end

    describe '#console_football' do
      it 'execs a rails console into the running football pod' do
        allow(runner).to receive(:pod_name).with('football').and_return('football-6d68fc48fd-crhzh')
        runner.console_football
        expect(captured_commands).to eq([
          "kubectl --kubeconfig=#{Constants::KUBECONFIG} exec -it football-6d68fc48fd-crhzh -- rails console"
        ])
      end
    end

    describe '#ingress' do
      it 'applies the ingress module and refreshes outputs' do
        runner.ingress
        expect(captured_commands).to eq([
          terraform('apply -target=module.ingress -var-file=../terraform.tfvars --auto-approve'),
          terraform("output -json > #{options[:output_file]}")
        ])
      end
    end

    describe '#kube' do
      it 'configures the app over Ansible without touching terraform' do
        runner.kube
        expect(captured_commands).to eq([ansible('kube')])
      end
    end

    describe '#destroy' do
      it 'dumps each app database before tearing anything down' do
        runner.destroy
        expect(captured_commands.first(2)).to eq([dump('auth'), dump('football')])
      end
    end

    describe '#apply' do
      it 'restores whichever database dumps exist locally, after kube' do
        allow(File).to receive(:exist?)
          .with("#{Constants::ROOT_DIR}/bin/outputs/dumps/#{env_name}/auth.sql").and_return(true)
        allow(File).to receive(:exist?)
          .with("#{Constants::ROOT_DIR}/bin/outputs/dumps/#{env_name}/football.sql").and_return(false)

        runner.apply

        expect(captured_commands.last).to eq(restore('auth'))
      end

      it 'restores nothing when no dump is present' do
        runner.apply
        expect(captured_commands.join(' ')).not_to include('psql')
      end
    end
  end

  describe Runners::Stage do
    let(:env_name) { 'stage' }
    let(:extra_ansible_variables) { ' -e domain_name=sports-app.test -e local_image_tag=prod' }

    include_examples 'a Cluster Runner'

    describe '#apply' do
      it 'never applies DNS, since Stage has no domain of its own' do
        runner.apply
        expect(captured_commands.join(' ')).not_to include('module.dns')
      end
    end

    describe '#destroy' do
      it 'tears down ingress, registry, and infra, skipping DNS' do
        runner.destroy
        expect(captured_commands).to eq([
          dump('auth'),
          dump('football'),
          terraform('destroy -target=module.ingress -var-file=../terraform.tfvars --auto-approve'),
          terraform('destroy -target=module.registry -var-file=../terraform.tfvars --auto-approve'),
          terraform('destroy -target=module.infra -var-file=../terraform.tfvars --auto-approve'),
          terraform("output -json > #{options[:output_file]}")
        ])
      end
    end
  end

  describe Runners::Prod do
    let(:env_name) { 'prod' }
    let(:extra_ansible_variables) { '' }

    include_examples 'a Cluster Runner'

    describe '#apply' do
      it 'applies DNS between ingress and kube, since Prod owns the real domain' do
        runner.apply
        dns_index = captured_commands.index { |c| c.include?('module.dns') }
        kube_index = captured_commands.index { |c| c.include?('--tags kube') }
        expect(dns_index).not_to be_nil
        expect(dns_index).to be < kube_index
      end
    end

    describe '#apply_base' do
      it 'applies everything except DNS' do
        runner.apply_base
        expect(captured_commands.join(' ')).not_to include('module.dns')
        expect(captured_commands.join(' ')).to include('--tags kube')
      end
    end

    describe '#destroy_base' do
      it 'tears down ingress and infra only, leaving DNS and the registry alone' do
        runner.destroy_base
        expect(captured_commands).to eq([
          terraform('destroy -target=module.ingress -var-file=../terraform.tfvars --auto-approve'),
          terraform('destroy -target=module.infra -var-file=../terraform.tfvars --auto-approve'),
          terraform("output -json > #{options[:output_file]}")
        ])
      end
    end
  end
end
