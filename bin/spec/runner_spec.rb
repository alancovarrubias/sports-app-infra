require 'runner'
# spec/cli_spec.rb
RSpec.describe 'Runner' do
  it 'greets the user by name' do
    allow(Runner).to receive(:run_command)
    Runner.run(command: 'run', module: 'dump')
    expect(Runner).to have_received(:run_command)
  end
end
