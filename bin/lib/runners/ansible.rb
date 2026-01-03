require 'json'
module Runners
  class Ansible
    def run(playbook:, variables: {}, inventory: nil, tags: nil, env: nil)
      command = []
      command << 'ansible-playbook -e @extra_vars.yml -e @custom_vars.yml'
      command << "--inventory #{inventory}," if inventory
      command << "--tags #{Array(tags).join(',')}" if tags
      command << "-e env=#{env}" if env
      variables.each do |key, value|
        command << "-e #{key}=#{value}"
      end
      command << "#{playbook}.yml"
      command.join(' ')
    end
  end
end
