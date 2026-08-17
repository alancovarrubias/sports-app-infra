RSpec.describe Commands::Terraform do
  subject(:command) { described_class.new(options) }

  let(:options) { { env: 'stage', output_file: '/tmp/stage.json' } }

  describe '#build' do
    it 'builds init' do
      expect(command.build('init')).to eq('terraform -chdir=stage init')
    end

    it 'builds output, redirecting the JSON dump to the output file' do
      expect(command.build('output')).to eq('terraform -chdir=stage output -json > /tmp/stage.json')
    end

    it 'builds kubeconfig, redirecting the raw value to the shared kubeconfig path' do
      expect(command.build('kubeconfig'))
        .to eq("terraform -chdir=stage output -raw kubeconfig > #{Constants::KUBECONFIG}")
    end

    it 'builds a bare apply with no Terraform module target' do
      expect(command.build('apply')).to eq('terraform -chdir=stage apply -var-file=../terraform.tfvars --auto-approve')
    end

    it 'builds an apply scoped to a Terraform module target' do
      expect(command.build('apply_infra'))
        .to eq('terraform -chdir=stage apply -target=module.infra -var-file=../terraform.tfvars --auto-approve')
    end

    it 'builds a bare destroy with no Terraform module target' do
      expect(command.build('destroy')).to eq('terraform -chdir=stage destroy -var-file=../terraform.tfvars --auto-approve')
    end

    it 'builds a destroy scoped to a Terraform module target' do
      expect(command.build('destroy_registry'))
        .to eq('terraform -chdir=stage destroy -target=module.registry -var-file=../terraform.tfvars --auto-approve')
    end
  end
end
