require 'rspec'

RSpec.describe 'ansible.rb' do
  let(:script_path) { File.expand_path('../infra_cli.rb', __dir__) }
  let(:ip_address) { '134.209.123.421' }

  before do
    allow_any_instance_of(Object).to receive(:system).with('bundle install')
    allow_any_instance_of(Object).to receive(:system).with('sudo bundle install')
  end

  describe 'terraform commands' do
    let(:mod) { 'dev' }
    let(:command) { 'apply' }
    let(:run_command) do
      "terraform -chdir=#{mod} #{command} -var-file=../terraform.tfvars --auto-approve"
    end
    let(:init_command) { "terraform -chdir=#{mod} init" }
    it 'sends the correct command to system for "apply"' do
      ARGV.replace(['-c', command, '-m', mod])
      expect_any_instance_of(Object).to receive(:system).with(init_command)
      expect_any_instance_of(Object).to receive(:system).with(run_command)
      load script_path
    end
  end

  describe 'ansible commands' do
    it 'sends the correct command to system for dumping a database' do
      ENV['WEB_IP'] = ip_address
      ARGV.replace(['-c', 'run', '-m', 'dump', '-e', 'dev', '--tags', 'dump'])
      command = "ansible-playbook --extra-vars @extra_vars.yml --skip-tags skip --inventory #{ip_address}, --tags dump -e env=dev database_cmd.yml"
      expect_any_instance_of(Object).to receive(:system).with(command)
      load script_path
    end
  end
end
