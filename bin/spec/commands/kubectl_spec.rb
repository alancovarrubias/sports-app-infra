RSpec.describe Commands::Kubectl do
  subject(:command) { described_class.new }

  describe '#restart' do
    it 'restarts a single deployment' do
      expect(command.restart(['client'])).to eq("kubectl --kubeconfig=#{Constants::KUBECONFIG} rollout restart deployment/client")
    end

    it 'restarts multiple deployments in one invocation' do
      expect(command.restart(%w[client server])).to eq(
        "kubectl --kubeconfig=#{Constants::KUBECONFIG} rollout restart deployment/client deployment/server"
      )
    end
  end

  describe '#exec' do
    it 'execs an interactive command into the given pod' do
      expect(command.exec('auth-6bf9797b6c-b4484', 'rails', 'console')).to eq(
        "kubectl --kubeconfig=#{Constants::KUBECONFIG} exec -it auth-6bf9797b6c-b4484 -- rails console"
      )
    end
  end
end
