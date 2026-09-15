module Commands
  class Kubectl
    include Constants

    def restart(deployments)
      build_command("rollout restart #{deployments.map { |d| "deployment/#{d}" }.join(' ')}")
    end

    def exec(pod, *command)
      build_command("exec -it #{pod} -- #{command.join(' ')}")
    end

    def wait_for_nodes
      build_command('wait --for=condition=Ready nodes --all --timeout=180s')
    end

    def build_command(command)
      "kubectl --kubeconfig=#{KUBECONFIG} #{command}"
    end
  end
end
