require 'runner'
# spec/cli_spec.rb
RSpec.describe 'Runner' do
  let(:inventory) { '143.110.207.14' }
  before do
    @command = Runner.run(command: 'run', module: mod, inventory: inventory)
  end
  describe 'jenkins command' do
    let(:mod) { 'jenkins' }
    it 'greets the user by name' do
      expect(@command).to eq("cd ansible && ansible-playbook --inventory #{inventory}, --extra-vars @extra_vars.yml --skip-tags skip  setup_jenkins.yml")
    end
  end
  describe 'dump command' do
    let(:mod) { 'dump' }
    it 'greets the user by name' do
      expect(@command).to eq("cd ansible && ansible-playbook --inventory #{inventory}, --extra-vars @extra_vars.yml --skip-tags skip --tags  database_cmd.yml")
    end
  end
end
