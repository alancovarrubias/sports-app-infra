module Commands
  class Dev < Base
    def apply
      @terraform_runner.run
      @ansible_runner.run
    end

    def destroy
      @terraform_runner.run
    end

    def run
      @terraform_runner.run
    end
  end
end
