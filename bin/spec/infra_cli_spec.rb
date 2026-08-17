require_relative '../infra_cli'

RSpec.describe InfraCLI do
  describe '.parse_options' do
    it 'parses command, environment, and tags into a hash' do
      ARGV.replace(['-c', 'apply', '-e', 'dev', '--tags', 'setup,server'])
      expect(InfraCLI.parse_options).to eq(command: 'apply', env: 'dev', tags: 'setup,server')
    end
  end

  describe '.run' do
    it 'instantiates the Runner named by --env and sends it the --command' do
      ARGV.replace(['-c', 'apply', '-e', 'dev'])
      runner = instance_double(Runners::Dev)
      allow(Runners::Dev).to receive(:new).with(hash_including(command: 'apply', env: 'dev')).and_return(runner)
      expect(runner).to receive(:apply)

      InfraCLI.run
    end

    it 'resolves --env to the matching Runners:: class, capitalized' do
      ARGV.replace(['-c', 'destroy', '-e', 'prod'])
      runner = instance_double(Runners::Prod)
      allow(Runners::Prod).to receive(:new).and_return(runner)
      expect(runner).to receive(:destroy)

      InfraCLI.run
    end
  end
end
