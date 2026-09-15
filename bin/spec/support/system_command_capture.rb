# Stubs Kernel#system across every object (Runners shell out via a bare
# `system(command)` call) and records what would have run, so specs can
# assert on the exact command built without ever executing it.
module SystemCommandCapture
  def captured_commands
    @captured_commands ||= []
  end

  def stub_system!
    @system_failures_remaining = 0
    allow_any_instance_of(Object).to receive(:system) do |_receiver, command|
      captured_commands << command
      if @system_failures_remaining.positive?
        @system_failures_remaining -= 1
        false
      else
        true
      end
    end
  end

  # Makes the next `count` calls to `system` report failure (returning
  # false), so specs can exercise retry logic without a real command failing.
  def fail_next_system_calls(count)
    @system_failures_remaining = count
  end
end
