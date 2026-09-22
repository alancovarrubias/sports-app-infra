RSpec.describe Runners::Cluster do
  shared_examples 'a Cluster Runner' do
    subject(:runner) { described_class.new(options) }

    let(:options) { { env: env_name, tags: nil, output_file: "/tmp/#{env_name}-cluster-spec.json" } }
    let(:fake_secret) { 'f' * 128 }
    let(:fake_outputs) do
      {
        'cache_uri' => { 'value' => 'redis://fake-cache' },
        'mongo_uri' => { 'value' => 'mongodb://fake-mongo' },
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
      allow_any_instance_of(Commands::Database).to receive(:database_exists?).and_return(true)
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
             "-e secret_key_base=#{fake_secret} -e cache_url=redis://fake-cache -e mongo_url=mongodb://fake-mongo " \
             "-e database_url=postgres://fake-db " \
             "-e auth_database_url=postgres://fake-db/auth_production " \
             "-e football_database_url=postgres://fake-db/football_production " \
             "-e registry_name=registry.digitalocean.com/fake -e kubeconfig=#{Constants::KUBECONFIG}"
      "#{base}#{extra_ansible_variables} setup_#{env_name}.yml"
    end

    describe '#infra' do
      it 'applies the infra Terraform module, pulls kubeconfig, refreshes outputs, ' \
         'then waits for the API server to be reachable' do
        runner.infra
        expect(captured_commands).to eq([
          terraform('init'),
          terraform('apply -target=module.infra -var-file=../terraform.tfvars --auto-approve'),
          terraform("output -raw kubeconfig > #{Constants::KUBECONFIG}"),
          terraform("output -json > #{options[:output_file]}"),
          "kubectl --kubeconfig=#{Constants::KUBECONFIG} wait --for=condition=Ready nodes --all --timeout=180s"
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

    describe '#console' do
      it 'execs a rails console into the running auth pod' do
        allow(runner).to receive(:pod_name).with('auth').and_return('auth-6bf9797b6c-b4484')
        options[:database] = 'auth'
        runner.console
        expect(captured_commands).to eq([
          "kubectl --kubeconfig=#{Constants::KUBECONFIG} exec -it auth-6bf9797b6c-b4484 -- rails console"
        ])
      end

      it 'execs a rails console into the running football pod' do
        allow(runner).to receive(:pod_name).with('football').and_return('football-6d68fc48fd-crhzh')
        options[:database] = 'football'
        runner.console
        expect(captured_commands).to eq([
          "kubectl --kubeconfig=#{Constants::KUBECONFIG} exec -it football-6d68fc48fd-crhzh -- rails console"
        ])
      end

      it 'aborts with a clear message when no pod is running for that database' do
        allow(runner).to receive(:pod_name).with('auth').and_return('')
        options[:database] = 'auth'
        expect { runner.console }.to raise_error(SystemExit)
        expect(captured_commands).to eq([])
      end

      it 'aborts with a clear message when no database is specified' do
        expect { runner.console }.to raise_error(SystemExit)
        expect(captured_commands).to eq([])
      end

      it 'aborts with a clear message when the database is unknown' do
        options[:database] = 'nonsense'
        expect { runner.console }.to raise_error(SystemExit)
        expect(captured_commands).to eq([])
      end
    end

    describe '#seed' do
      it 'runs seeds.rb in the running football pod' do
        allow(runner).to receive(:pod_name).with('football').and_return('football-6d68fc48fd-crhzh')
        options[:database] = 'football'
        runner.seed
        expect(captured_commands).to eq([
          "kubectl --kubeconfig=#{Constants::KUBECONFIG} exec -it football-6d68fc48fd-crhzh -- " +
            %(rails runner "load Rails.root.join('db/seeds.rb')")
        ])
      end

      it 'aborts with a clear message when no pod is running for that database' do
        allow(runner).to receive(:pod_name).with('football').and_return('')
        options[:database] = 'football'
        expect { runner.seed }.to raise_error(SystemExit)
        expect(captured_commands).to eq([])
      end

      it 'aborts with a clear message when no database is specified' do
        expect { runner.seed }.to raise_error(SystemExit)
        expect(captured_commands).to eq([])
      end

      it 'aborts with a clear message when the database is unknown' do
        options[:database] = 'nonsense'
        expect { runner.seed }.to raise_error(SystemExit)
        expect(captured_commands).to eq([])
      end
    end

    describe '#dump' do
      it 'dumps the given database' do
        options[:database] = 'auth'
        runner.dump
        expect(captured_commands).to eq([dump('auth')])
      end

      it 'aborts with a clear message when no database is specified' do
        expect { runner.dump }.to raise_error(SystemExit)
        expect(captured_commands).to eq([])
      end

      it 'aborts with a clear message when the database is unknown' do
        options[:database] = 'nonsense'
        expect { runner.dump }.to raise_error(SystemExit)
        expect(captured_commands).to eq([])
      end
    end

    describe '#restore' do
      it 'restores the given database when a dump is present locally' do
        allow(File).to receive(:exist?)
          .with("#{Constants::ROOT_DIR}/bin/outputs/dumps/#{env_name}/auth.sql").and_return(true)
        options[:database] = 'auth'
        runner.restore
        expect(captured_commands).to eq([restore('auth')])
      end

      it 'does nothing when no dump is present locally' do
        options[:database] = 'auth'
        runner.restore
        expect(captured_commands).to eq([])
      end

      it 'aborts with a clear message when no database is specified' do
        expect { runner.restore }.to raise_error(SystemExit)
        expect(captured_commands).to eq([])
      end

      it 'aborts with a clear message when the database is unknown' do
        options[:database] = 'nonsense'
        expect { runner.restore }.to raise_error(SystemExit)
        expect(captured_commands).to eq([])
      end
    end

    describe '#ingress' do
      let(:apply_ingress) { terraform('apply -target=module.ingress -var-file=../terraform.tfvars --auto-approve') }

      it 'applies the ingress module and refreshes outputs' do
        runner.ingress
        expect(captured_commands).to eq([
          apply_ingress,
          terraform("output -json > #{options[:output_file]}")
        ])
      end

      it 'retries after a transient failure, then succeeds' do
        fail_next_system_calls(1)
        allow(runner).to receive(:sleep)

        runner.ingress

        expect(captured_commands).to eq([
          apply_ingress,
          apply_ingress,
          terraform("output -json > #{options[:output_file]}")
        ])
        expect(runner).to have_received(:sleep).once
      end

      it 'gives up after exhausting its retries on a persistent failure' do
        fail_next_system_calls(10)
        allow(runner).to receive(:sleep)

        expect { runner.ingress }.to raise_error(SystemExit)
        expect(captured_commands).to eq([apply_ingress, apply_ingress, apply_ingress])
        expect(runner).to have_received(:sleep).twice
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

  context 'for stage' do
    let(:env_name) { 'stage' }
    let(:extra_ansible_variables) { ' -e domain_name=sports-app.test -e local_image_tag=prod' }

    include_examples 'a Cluster Runner'

    describe '#apply' do
      it 'never applies DNS, since stage has no domain of its own' do
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

  context 'for prod' do
    let(:env_name) { 'prod' }
    let(:extra_ansible_variables) { '' }

    include_examples 'a Cluster Runner'

    describe '#apply' do
      it 'applies DNS between ingress and kube, since prod owns the real domain' do
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
