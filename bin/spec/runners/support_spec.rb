RSpec.describe Runners::Support do
  subject(:runner) { described_class.new }

  before { stub_system! }

  def terraform(stack, *rest)
    "terraform -chdir=terraform/#{stack} #{rest.join(' ')}"
  end

  describe '#apply' do
    it 'inits and applies each support stack with its own local tfvars' do
      runner.apply
      expect(captured_commands).to eq([
        terraform('datadog', 'init -input=false'),
        terraform('datadog', 'apply -var-file=terraform.tfvars --auto-approve')
      ])
    end

    it 'aborts without trying the next stack when one fails' do
      stub_const('Runners::Support::STACKS', %w[datadog jenkins])
      fail_next_system_calls(1)

      expect { runner.apply }.to raise_error(SystemExit)
      expect(captured_commands).to eq([terraform('datadog', 'init -input=false')])
    end
  end
end
