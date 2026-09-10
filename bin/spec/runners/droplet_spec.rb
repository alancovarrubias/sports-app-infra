RSpec.describe Runners::Droplet do
  shared_examples 'a Droplet Runner' do
    subject(:runner) { described_class.new(options) }

    let(:options) { { env: env_name, tags: nil, output_file: "/tmp/#{env_name}-droplet-spec.json" } }

    before do
      stub_system!
      allow(runner).to receive(:outputs).and_return('web_ip' => { 'value' => '1.2.3.4' })
    end

    def terraform(*rest)
      "terraform -chdir=#{env_name} #{rest.join(' ')}"
    end

    describe '#apply' do
      it 'applies terraform, then configures the droplet over the applied IP' do
        runner.apply
        expect(captured_commands).to eq([
          terraform('init'),
          terraform('apply -var-file=../terraform.tfvars --auto-approve'),
          terraform("output -json > #{options[:output_file]}"),
          expected_ansible_command
        ])
      end
    end

    describe '#destroy' do
      it 'destroys the droplet' do
        runner.destroy
        expect(captured_commands).to eq([
          terraform('init'),
          terraform('destroy -var-file=../terraform.tfvars --auto-approve'),
          terraform("output -json > #{options[:output_file]}")
        ])
      end
    end

    describe '#run' do
      it 'reconfigures the droplet without touching terraform' do
        runner.run
        expect(captured_commands).to eq([expected_ansible_command])
      end
    end

    describe '#database' do
      it 'runs database_cmd against the droplet, tagged and scoped to the environment' do
        options[:tags] = 'dump'
        runner.database
        expect(captured_commands).to eq([
          'ansible-playbook -e @extra_vars.yml -e @custom_vars.yml --inventory 1.2.3.4, --tags dump ' \
          "-e env=#{env_name} database_cmd.yml"
        ])
      end
    end
  end

  context 'for dev' do
    let(:env_name) { 'dev' }
    let(:expected_ansible_command) do
      'ansible-playbook -e @extra_vars.yml -e @custom_vars.yml --inventory 1.2.3.4, ' \
        '--tags setup,server,docker,create,client,dev -e env=dev setup_dev.yml'
    end

    include_examples 'a Droplet Runner'

    it 'falls back to its own default tags when none are given' do
      runner # instantiate before stubbing tags, mirroring how the CLI leaves --tags unset
      runner.run
      expect(captured_commands.first).to include('--tags setup,server,docker,create,client,dev')
    end
  end

  context 'for mercor' do
    let(:env_name) { 'mercor' }
    let(:expected_ansible_command) do
      'ansible-playbook -e @extra_vars.yml -e @custom_vars.yml --inventory 1.2.3.4, -e env=mercor setup_mercor.yml'
    end

    include_examples 'a Droplet Runner'

    it 'has no default tags of its own, so an untagged run means "run everything"' do
      runner
      runner.run
      expect(captured_commands.first).not_to include('--tags')
    end
  end
end
