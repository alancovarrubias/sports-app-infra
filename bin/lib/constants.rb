module Constants
  TERRAFORM = 'terraform'.freeze
  ANSIBLE = 'ansible'.freeze
  OUTPUTS_DIR = File.join(InfraCLI::ROOT_DIR, 'bin/outputs')
  KUBECONFIG = File.expand_path('~/.kube/sports-app.yaml')
end
