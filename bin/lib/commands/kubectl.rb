module Commands
  class Kubectl
    include Constants

    def restart(deployments)
      "kubectl --kubeconfig=#{KUBECONFIG} rollout restart #{deployments.map { |d| "deployment/#{d}" }.join(' ')}"
    end

    def exec(pod, *command)
      "kubectl --kubeconfig=#{KUBECONFIG} exec -it #{pod} -- #{command.join(' ')}"
    end
  end
end
