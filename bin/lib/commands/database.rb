require 'uri'
require 'fileutils'

module Commands
  class Database
    include Constants

    CONTAINERS = %w[auth football].freeze

    def initialize(options)
      @options = options
    end

    def validate!(db)
      abort("No database specified -- pass -d <#{CONTAINERS.join('|')}>") if db.nil?
      abort("Unknown database '#{db}' -- expected one of #{CONTAINERS.join(', ')}") unless CONTAINERS.include?(db)

      db
    end

    def dump(base_uri, db)
      run(dump_command(base_uri, validate!(db)))
    end

    def dump_all(base_uri)
      CONTAINERS.each { |db| run(dump_command(base_uri, db)) }
    end

    def restore(base_uri, db)
      run(restore_command(base_uri, validate!(db)))
    end

    def restore_all(base_uri)
      CONTAINERS.each { |db| run(restore_command(base_uri, db)) }
    end

    def uri(base_uri, db)
      parsed = URI.parse(base_uri)
      parsed.path = "/#{db}_production"
      parsed.to_s
    end

    private

    def dump_command(base_uri, db)
      FileUtils.mkdir_p(dump_dir)
      "#{pg_bin('pg_dump')} \"#{uri(base_uri, db)}\" --data-only --no-owner -f #{dump_file(db)}"
    end

    def restore_command(base_uri, db)
      return nil unless File.exist?(dump_file(db))

      "#{pg_bin('psql')} \"#{uri(base_uri, db)}\" -f #{dump_file(db)}"
    end

    def run(command)
      return unless command

      puts command
      abort("Command failed, stopping: #{command}") unless system(command)
    end

    def pg_bin(command)
      "$(brew --prefix postgresql@18)/bin/#{command}"
    end

    def dump_dir
      File.join(ROOT_DIR, 'bin/outputs/dumps', @options[:env])
    end

    def dump_file(db)
      File.join(dump_dir, "#{db}.sql")
    end
  end
end
