module Commands
  class Kubectl
    include Constants

    def build(deployments)
      "kubectl --kubeconfig=#{KUBECONFIG} rollout restart #{deployments.map { |d| "deployment/#{d}" }.join(' ')}"
    end
  end
end
