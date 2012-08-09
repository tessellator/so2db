#--
# Copyright (c) 2012 Chad Taylor
#
# Permission is hereby granted, free of charge, to any person obtaining a copy 
# of this software and associated documentation files (the "Software"), to deal 
# in the Software without restriction, including without limitation the rights 
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
# copies of the Software, and to permit persons to whom the Software is 
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in 
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
# SOFTWARE.

require 'optparse'
require 'so2db'

module ActiveRecord::ConnectionAdapters
  class PostgreSQLAdapter < AbstractAdapter

    # Extends the adapter to include support for a uuid type.  This is required
    # by the importer (see SO2DB::Importer for more information).  For 
    # PostgreSQL, simply use the native 'uuid' type (for MySQL, use something
    # a bit more contrived, like CHAR(16)).
    def uuid
      return 'uuid', {}
    end
  end
end

# Imports the StackOverflow data into a PostgreSQL data.
class PgImporter < SO2DB::Importer

  # (See SO2DB::Importer.initialize documentation)
  def initialize(relations = false, optionals = false, options = {})
    super(relations, optionals, "postgresql", options)
  end

  def self.import_from_argv(argv)
    # Parse the command-line options
    cmd_opts = PgOptionsParser.parse(ARGV)

    # If all validation passed, then execute the import!
    if cmd_opts
      start = Time.now
      pg = PgImporter.new(cmd_opts.has_key?(:relationships),
                          cmd_opts.has_key?(:optionals),
                          cmd_opts)
      pg.import(cmd_opts[:dir])
      puts "Import completed in #{Time.now - start}s"
    end
  end

  private

  # Imports the data from the formatter into the PostgreSQL database.
  #
  # Note that what follows is just one way to implement the importer.  You
  # could just as easily push the formatted data into a file and then ask
  # the database to suck that file in.
  def import_stream(formatter)
    puts "Importing file #{formatter.file_name}..."
    start = Time.now

    sql = build_sql(formatter.value_str)
    cmd = build_cmd(sql)
    execute_cmd(cmd, formatter)

    puts "   -> #{Time.now - start}s"
  end

  # Builds the SQL command used for bulk loading the tables.
  def build_sql(value_str)
    "COPY #{value_str} FROM STDIN WITH (FORMAT csv, DELIMITER E'\x0B')"
  end

  # Builds the import command with the given SQL command and the global
  # connection options.
  #   
  # Example:
  #   >> sql = "COPY ..."
  #   >> puts build_cmd(sql)
  #   => psql -d test -h localhost -c "COPY ..."
  def build_cmd(sql)
    # Only exists within the context of this script (not exported), so this
    # does not degrade security posture after the script has completed
    ENV['PGPASSWORD'] = conn_opts[:password] if conn_opts.has_key? :password

    cmd = "psql"
    cmd << " -d #{conn_opts[:database]}" if conn_opts.has_key? :database
    cmd << " -h #{conn_opts[:host]}" if conn_opts.has_key? :host
    cmd << " -U #{conn_opts[:username]}" if conn_opts.has_key? :username
    cmd << " -p #{conn_opts[:port]}" if conn_opts.has_key? :port
    cmd << " -c \"#{sql}\""

    return cmd
  end

  # Executes the provided shell command and pumps the data from the formatter
  # to it over stdin.
  def execute_cmd(cmd, formatter)
    IO.popen(cmd, 'r+') do |s|
      formatter.format(s)
      s.close_write
    end
  end

end

class PgOptionsParser

  # Parses the command-line arguments into a Hash object.  Note that the members
  # of the Hash have the same name as the ActiveRecord parameters (e.g., :host,
  # :database, etc.).  This Hash will actually be passed to ActiveRecord for
  # consumption.
  def self.parse(args)
    options = {}

    opts = OptionParser.new do |opts|
      opts.banner = <<-EOB
Imports a StackOverflow data dump into a PostgreSQL database.
Usage: so2pg [options]
      EOB

      opts.on("-H", "--host HOST", "The database host") do |host|
        options[:host] = host
      end

      opts.on("-d", "--database DBNAME", "The name of the database (REQUIRED)") do |dbname|
        options[:database] = dbname
      end

      opts.on("-D", "--directory DIRECTORY", "The data directory path (REQUIRED)") do |dir|
        options[:dir] = dir
      end

      opts.on("-u", "--user USER", "The user name") do |user|
        options[:username] = user
      end

      opts.on("-p", "--password PASSWORD", "The user's password") do |password|
        options[:password] = password
      end

      opts.on("-P", "--port PORT_NUMBER", "The port number") do |port|
        options[:port] = port
      end

      opts.on("-O", "--include-optionals", "Includes optional tables") do
        options[:optionals] = true
      end

      opts.on("-R", "--include-relationships", "Includes table relationships") do
        options[:relationships] = true
      end

      opts.on("-h", "--help", "Show this help screen") do |help|
        options[:help] = true
      end

    end

    opts.parse!(args)
    if(options[:help] or !options.has_key? :dir or !options.has_key? :database)
      puts opts.help
      nil
    else
      options
    end
  end

end
