module Constants
  TERRAFORM = 'terraform'.freeze
  ANSIBLE = 'ansible'.freeze
  OUTPUTS_DIR = File.join(InfraCLI::ROOT_DIR, 'bin/outputs')
  KUBECONFIG = '~/.kube/sports-app.yaml'.freeze
end
