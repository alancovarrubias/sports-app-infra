module Runners
  # One-time, account-level setup -- Terraform "support stacks" (README,
  # CONTEXT.md) that aren't tied to any Environment, so they never go
  # through a Cluster/Droplet Runner's apply/destroy lifecycle. Applied
  # once to create the resources, and again only when their own config
  # changes -- never as part of a regular Environment deploy. Not keyed
  # by `-e`, since "which Environment" doesn't apply here.
  class Support
    include Constants

    # Each support stack keeps its own (gitignored) terraform.tfvars
    # inside its own directory, unlike Environment stacks, which share
    # one terraform/terraform.tfvars via `-var-file=../terraform.tfvars`.
    STACKS = %w[datadog].freeze

    def apply
      STACKS.each { |stack| apply_stack(stack) }
    end

    private

    def apply_stack(stack)
      dir = "terraform/#{stack}"
      run("terraform -chdir=#{dir} init -input=false")
      run("terraform -chdir=#{dir} apply -var-file=terraform.tfvars --auto-approve")
    end

    def run(command)
      puts command
      Dir.chdir(ROOT_DIR) do
        abort("Command failed, stopping: #{command}") unless system(command)
      end
    end
  end
end
