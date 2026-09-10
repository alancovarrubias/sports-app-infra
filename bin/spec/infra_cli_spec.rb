require_relative '../infra_cli'

RSpec.describe InfraCLI do
  describe '.parse_options' do
    it 'parses command, environment, and tags into a hash' do
      ARGV.replace(['-c', 'apply', '-e', 'dev', '--tags', 'setup,server'])
      expect(InfraCLI.parse_options).to eq(command: 'apply', env: 'dev', tags: 'setup,server')
    end
  end

  describe '.run' do
    it 'instantiates the droplet Runner for dev/mercor and sends it the --command' do
      ARGV.replace(['-c', 'apply', '-e', 'dev'])
      runner = instance_double(Runners::Droplet)
      allow(Runners::Droplet).to receive(:new).with(hash_including(command: 'apply', env: 'dev')).and_return(runner)
      expect(runner).to receive(:apply)

      InfraCLI.run
    end

    it 'instantiates the cluster Runner for stage/prod and sends it the --command' do
      ARGV.replace(['-c', 'destroy', '-e', 'prod'])
      runner = instance_double(Runners::Cluster)
      allow(Runners::Cluster).to receive(:new).and_return(runner)
      expect(runner).to receive(:destroy)

      InfraCLI.run
    end

    it 'aborts with a clear message for an unknown environment' do
      ARGV.replace(['-c', 'apply', '-e', 'nonsense'])
      expect { InfraCLI.run }.to raise_error(SystemExit)
    end
  end
end
