require 'uri'
require 'json'
require 'fileutils'

module Commands
  class Mongo
    include Constants

    # DO-managed system databases that ship with every cluster -- never
    # part of the app's own data, and dumping/restoring them could corrupt
    # a cluster's internal auth/replication state.
    SYSTEM_DATABASES = %w[admin config local].freeze

    def initialize(options)
      @options = options
    end

    def dump_all(base_uri)
      FileUtils.mkdir_p(dump_dir)
      app_databases(base_uri).each { |db| run(dump_command(base_uri, db)) }
    end

    def restore_all(base_uri)
      local_dumps.each { |db| run(restore_command(base_uri, db)) }
    end

    def uri(base_uri, db)
      parsed = URI.parse(base_uri)
      parsed.path = "/#{db}"
      parsed.to_s
    end

    private

    # The crawler creates one Mongo database per sport/league it scrapes
    # (DbManager in sports-app's crawler), not a fixed set the way
    # Postgres's CONTAINERS is -- discover whatever actually exists rather
    # than hardcoding sport/league names that can grow over time.
    def app_databases(base_uri)
      names = `mongosh "#{base_uri}" --quiet --eval "EJSON.stringify(db.adminCommand('listDatabases').databases.map(d => d.name))"`
      JSON.parse(names) - SYSTEM_DATABASES
    end

    def local_dumps
      return [] unless Dir.exist?(dump_dir)

      Dir.children(dump_dir)
    end

    def dump_command(base_uri, db)
      "mongodump --uri=\"#{uri(base_uri, db)}\" --out=#{dump_dir}"
    end

    def restore_command(base_uri, db)
      "mongorestore --uri=\"#{uri(base_uri, db)}\" --drop #{File.join(dump_dir, db)}"
    end

    def run(command)
      return unless command

      puts command
      abort("Command failed, stopping: #{command}") unless system(command)
    end

    def dump_dir
      File.join(ROOT_DIR, 'bin/outputs/dumps', @options[:env], 'mongo')
    end
  end
end
