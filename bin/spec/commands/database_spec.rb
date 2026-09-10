RSpec.describe Commands::Database do
  subject(:command) { described_class.new(env: 'stage') }

  let(:base_uri) { 'postgres://fake-db' }

  before do
    stub_system!
    allow(FileUtils).to receive(:mkdir_p)
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(/bin\/outputs\/dumps/).and_return(true)
  end

  def dump_file(db)
    "#{Constants::ROOT_DIR}/bin/outputs/dumps/stage/#{db}.sql"
  end

  def dump_command(db)
    "$(brew --prefix postgresql@18)/bin/pg_dump \"postgres://fake-db/#{db}_production\" --data-only --no-owner " \
      "-f #{dump_file(db)}"
  end

  def restore_command(db)
    "$(brew --prefix postgresql@18)/bin/psql \"postgres://fake-db/#{db}_production\" -f #{dump_file(db)}"
  end

  describe '#validate!' do
    it 'returns the database when it is known' do
      expect(command.validate!('auth')).to eq('auth')
    end

    it 'aborts with a clear message when no database is given' do
      expect { command.validate!(nil) }.to raise_error(SystemExit)
    end

    it 'aborts with a clear message when the database is unknown' do
      expect { command.validate!('nonsense') }.to raise_error(SystemExit)
    end
  end

  describe '#uri' do
    it 'points the base connection string at the given database' do
      expect(command.uri(base_uri, 'auth')).to eq('postgres://fake-db/auth_production')
    end
  end

  describe '#dump' do
    it 'creates the dump directory and runs pg_dump scoped to the given database' do
      command.dump(base_uri, 'auth')
      expect(FileUtils).to have_received(:mkdir_p).with("#{Constants::ROOT_DIR}/bin/outputs/dumps/stage")
      expect(captured_commands).to eq([dump_command('auth')])
    end

    it 'aborts with a clear message when the database is unknown' do
      expect { command.dump(base_uri, 'nonsense') }.to raise_error(SystemExit)
      expect(captured_commands).to eq([])
    end
  end

  describe '#dump_all' do
    it 'dumps every known database' do
      command.dump_all(base_uri)
      expect(captured_commands).to eq([dump_command('auth'), dump_command('football')])
    end
  end

  describe '#restore' do
    it 'runs psql scoped to the given database when a dump is present locally' do
      command.restore(base_uri, 'auth')
      expect(captured_commands).to eq([restore_command('auth')])
    end

    it 'does nothing when no dump is present locally' do
      allow(File).to receive(:exist?).with(/bin\/outputs\/dumps/).and_return(false)
      command.restore(base_uri, 'auth')
      expect(captured_commands).to eq([])
    end

    it 'aborts with a clear message when the database is unknown' do
      expect { command.restore(base_uri, 'nonsense') }.to raise_error(SystemExit)
      expect(captured_commands).to eq([])
    end
  end

  describe '#restore_all' do
    it 'restores every known database that has a local dump' do
      command.restore_all(base_uri)
      expect(captured_commands).to eq([restore_command('auth'), restore_command('football')])
    end

    it 'skips databases with no local dump' do
      allow(File).to receive(:exist?).with(dump_file('football')).and_return(false)
      command.restore_all(base_uri)
      expect(captured_commands).to eq([restore_command('auth')])
    end
  end
end
