# spec/cli_spec.rb
RSpec.describe 'CommandBuilder' do
  subject { CommandBuilder.new(inventory: inventory, tags: tags, playbook: playbook, args: args) }
  let(:inventory) { '157.245.176.145' }
  let(:playbook) { 'playbook.yml' }
  let(:tags) { 'tags' }
  let(:args) { { key: 'value' } }
  it 'creates the correct ansible command' do
    expect(subject.ansible).to eq("ansible-playbook --inventory #{inventory}, --extra-vars @extra_vars.yml --skip-tags skip --tags #{tags} -e #{args.keys.first}=#{args.values.first} #{playbook}")
  end
end
