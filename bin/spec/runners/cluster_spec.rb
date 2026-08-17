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
