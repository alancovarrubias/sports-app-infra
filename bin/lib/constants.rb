module Constants
  TERRAFORM = 'terraform'.freeze
  ANSIBLE = 'ansible'.freeze
  ROOT_DIR = File.expand_path('../..', __dir__)
  OUTPUTS_DIR = File.join(ROOT_DIR, 'bin/outputs')
  KUBECONFIG = File.expand_path('~/.kube/sports-app.yaml')
end
