RSpec.describe Commands::Kubectl do
  subject(:command) { described_class.new }

  describe '#build' do
    it 'restarts a single deployment' do
      expect(command.build(['client'])).to eq("kubectl --kubeconfig=#{Constants::KUBECONFIG} rollout restart deployment/client")
    end

    it 'restarts multiple deployments in one invocation' do
      expect(command.build(%w[client server])).to eq(
        "kubectl --kubeconfig=#{Constants::KUBECONFIG} rollout restart deployment/client deployment/server"
      )
    end
  end
end
