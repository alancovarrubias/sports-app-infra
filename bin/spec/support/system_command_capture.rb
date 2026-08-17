# Stubs Kernel#system across every object (Runners shell out via a bare
# `system(command)` call) and records what would have run, so specs can
# assert on the exact command built without ever executing it.
module SystemCommandCapture
  def captured_commands
    @captured_commands ||= []
  end

  def stub_system!
    allow_any_instance_of(Object).to receive(:system) do |_receiver, command|
      captured_commands << command
      true
    end
  end
end
