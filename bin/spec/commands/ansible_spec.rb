RSpec.describe Commands::Ansible do
  subject(:command) { described_class.new }

  describe '#build' do
    it 'builds the minimal command for a playbook with no extras' do
      result = command.build(playbook: 'setup_dev')
      expect(result).to eq('ansible-playbook -e @extra_vars.yml -e @custom_vars.yml setup_dev.yml')
    end

    it 'includes an inventory when given' do
      result = command.build(playbook: 'setup_dev', inventory: '1.2.3.4')
      expect(result).to eq('ansible-playbook -e @extra_vars.yml -e @custom_vars.yml --inventory 1.2.3.4, setup_dev.yml')
    end

    it 'joins multiple tags with commas' do
      result = command.build(playbook: 'setup_dev', tags: %w[setup server])
      expect(result).to eq('ansible-playbook -e @extra_vars.yml -e @custom_vars.yml --tags setup,server setup_dev.yml')
    end

    it 'includes env as an extra var' do
      result = command.build(playbook: 'setup_dev', env: 'dev')
      expect(result).to eq('ansible-playbook -e @extra_vars.yml -e @custom_vars.yml -e env=dev setup_dev.yml')
    end

    it 'includes each variable as its own extra var' do
      result = command.build(playbook: 'setup_stage', variables: { cache_url: 'redis://x', database_url: 'postgres://y' })
      expect(result).to eq(
        'ansible-playbook -e @extra_vars.yml -e @custom_vars.yml -e cache_url=redis://x -e database_url=postgres://y setup_stage.yml'
      )
    end

    it 'combines inventory, tags, env, and variables in a fixed order' do
      result = command.build(
        playbook: 'database_cmd',
        inventory: '1.2.3.4',
        tags: 'dump',
        env: 'dev',
        variables: { foo: 'bar' }
      )
      expect(result).to eq(
        'ansible-playbook -e @extra_vars.yml -e @custom_vars.yml --inventory 1.2.3.4, --tags dump -e env=dev -e foo=bar database_cmd.yml'
      )
    end
  end
end
