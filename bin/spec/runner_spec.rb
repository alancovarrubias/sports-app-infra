require 'runner'
# spec/cli_spec.rb
RSpec.describe 'Runner' do
  subject { Runner.new(command: 'run', module: 'dump') }
  it 'runs run_command' do
    allow(subject).to receive(:run_command)
    subject.run
    expect(subject).to have_received(:run_command)
  end
end
