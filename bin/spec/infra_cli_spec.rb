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
    def terraform_command
      "terraform -chdir=$(pwd)/terraform/#{mod} #{command} -var-file=$(pwd)/terraform/terraform.tfvars --auto-approve"
    end
    it 'sends the correct command to system for "apply"' do
      ARGV.replace(['-c', command, '-m', mod])
      expect_any_instance_of(Object).to receive(:system).with(terraform_command)
      load script_path
    end
  end

  describe 'ansible commands' do
    it 'sends the correct command to system for dumping a database' do
      ENV['WEB_IP'] = ip_address
      ARGV.replace(['-c', 'run', '-m', 'dump', '-e', 'dev', '--tags', 'dump'])
      expect_any_instance_of(Object).to receive(:system).with("cd ansible && ansible-playbook --inventory #{ip_address}, --extra-vars @extra_vars.yml --skip-tags skip --tags dump -e env=dev database_cmd.yml")
      load script_path
    end
  end
end
