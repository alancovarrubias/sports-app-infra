module Commands
  class Prod < Base
    def apply
      @terraform_runner.prod_infra
      @ansible_runner.prod_infra
      @terraform_runner.prod_kube
      @ansible_runner.prod_kube
    end

    def destroy
      @terraform_runner.prod_destroy
    end
  end
end
