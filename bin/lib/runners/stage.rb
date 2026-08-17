module Runners
  class Stage < Cluster
    private

    def ansible_variables
      super.merge(
        domain_name: 'sports-app.test',
        local_image_tag: 'prod'
      )
    end
  end
end
