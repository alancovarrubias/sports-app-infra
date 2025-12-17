module Constants
  TERRAFORM_WORKING_DIR = File.join(InfraCLI::ROOT_DIR, 'terraform')
  ANSIBLE_WORKING_DIR = File.join(InfraCLI::ROOT_DIR, 'ansible')
  OUTPUTS_DIR = File.join(InfraCLI::ROOT_DIR, 'bin/outputs')
  KUBECONFIG = '~/.kube/sports-app.yaml'.freeze
  APPLY_COMMAND = 'apply'.freeze
  DESTROY_COMMAND = 'destroy'.freeze
  RUN_COMMAND = 'run'.freeze
end
