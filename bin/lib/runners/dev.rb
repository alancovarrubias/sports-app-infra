module Runners
  class Dev < Droplet
    private

    def playbook
      'setup_dev'
    end

    def default_tags
      %w[setup server docker create client dev]
    end
  end
end
