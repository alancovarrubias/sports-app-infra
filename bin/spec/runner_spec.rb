require 'runner'
# spec/cli_spec.rb
RSpec.describe 'Runner' do
  it 'greets the user by name' do
    expect(Runner.run(command: 'run',
                      module: 'dump')).to eq('cd ansible && ansible-playbook --inventory 143.110.207.14, --extra-vars @extra_vars.yml --skip-tags skip --tags  database_cmd.yml')
  end
end
