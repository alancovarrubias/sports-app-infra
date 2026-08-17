module Runners
  class Prod < Cluster
    def apply_base
      infra
      registry
      ingress
      kube
    end

    def destroy_base
      run_terraform('destroy_ingress', 'destroy_infra', 'output')
    end

    private

    def dns?
      true
    end
  end
end
