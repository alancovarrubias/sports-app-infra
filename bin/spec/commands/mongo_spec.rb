RSpec.describe Commands::Mongo do
  subject(:command) { described_class.new(env: 'stage') }

  let(:base_uri) { 'mongodb+srv://fake-db/admin?tls=true' }

  before do
    stub_system!
    allow(FileUtils).to receive(:mkdir_p)
  end

  def dump_dir
    "#{Constants::ROOT_DIR}/bin/outputs/dumps/stage/mongo"
  end

  def scoped_uri(db)
    "mongodb+srv://fake-db/#{db}?tls=true"
  end

  def dump_command(db)
    "mongodump --uri=\"#{scoped_uri(db)}\" --out=#{dump_dir}"
  end

  def restore_command(db)
    "mongorestore --uri=\"#{scoped_uri(db)}\" --drop #{dump_dir}/#{db}"
  end

  describe '#uri' do
    it 'points the base connection string at the given database' do
      expect(command.uri(base_uri, 'nba')).to eq(scoped_uri('nba'))
    end
  end

  describe '#dump_all' do
    it 'dumps every non-system database the cluster actually has' do
      allow(command).to receive(:app_databases).with(base_uri).and_return(%w[nba mlb])
      command.dump_all(base_uri)
      expect(FileUtils).to have_received(:mkdir_p).with(dump_dir)
      expect(captured_commands).to eq([dump_command('nba'), dump_command('mlb')])
    end

    it 'excludes DO-managed system databases' do
      allow(command).to receive(:`)
        .with(/mongosh/)
        .and_return('["admin","config","local","nba"]')
      command.dump_all(base_uri)
      expect(captured_commands).to eq([dump_command('nba')])
    end
  end

  describe '#restore_all' do
    it 'restores every database with a local dump present' do
      allow(Dir).to receive(:exist?).with(dump_dir).and_return(true)
      allow(Dir).to receive(:children).with(dump_dir).and_return(%w[nba mlb])
      command.restore_all(base_uri)
      expect(captured_commands).to eq([restore_command('nba'), restore_command('mlb')])
    end

    it 'does nothing when no local dumps are present' do
      allow(Dir).to receive(:exist?).with(dump_dir).and_return(false)
      command.restore_all(base_uri)
      expect(captured_commands).to eq([])
    end
  end
end
