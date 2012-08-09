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

module SO2DB

  # Base class for StackOverflow data importers.  Drives database setup and
  # data importing files from a directory.
  #
  # Implementations of this class must provide a method with the following 
  # signature:
  #
  #   import_stream(formatter)
  #
  # This method may be private.  The purpose of this method is to actually
  # perform the data import with data from the provided formatter.  The
  # formatter is provided to support scenarios of streaming data to STDIN 
  # (e.g., PostgreSQL's COPY command) as well as pushing data to a file before 
  # import (e.g., for MySQL's mysqlimport utility).  It has type 
  # SO2DB::Formatter.
  #
  # The importer uses ActiveRecord for table creation and Foreigner for creating
  # table relationships. You are limited to the databases supported by these 
  # libraries.  In addition, a 'uuid' method must be avaiable to the adapter
  # provided to ActiveRecord.  (See so2pg for an example of an adapter extension
  # that provides the method.)
  #
  # In addition, it provides two accessors for subclasses:
  #
  #   attr_reader :conn_opts
  #   attr_accessor :delimiter
  #
  # The conn_opts property provides the ActiveRecord connection data (e.g., 
  # :database, :host, etc.).  The delimiter property sets the delimiter used by
  # the formatter.  The delimiter is \v (0xB) by default.
  class Importer

    # Initializes the importer.
    #
    # Arguments:
    #   relations: (Boolean) Indicates whether database relationships should
    #                        be created.
    #   optionals: (Boolean) Indicates whether optional database tables and
    #                        content should be created.
    #   adapter:   (String)  The ActiveRecord adapter name (e.g., 'postgresql').
    #   options:   (Hash)    The database connection options, as required by
    #                        ActiveRecord for the provided adapter.
    def initialize(relations = false, optionals = false, adapter = '', options = {})
      @relations = relations
      @optionals = optionals
      @conn_opts = options.merge( { :adapter => adapter } )
      @format_delimiter = 11.chr.to_s
    end

    # Creates the database tables and relationships, and imports the data in
    # the files in the specified directory.  
    #
    # Arguments:
    #   dir:  (String) The directory path containting the StackOverflow data
    #                  dump XML files (e.g., badges.xml, posts.xml, etc.).
    def import(dir)
      setup
      create_basics
      import_data(dir)
      create_relations if @relations
      create_optionals if @optionals
      create_optional_relations if @relations and @optionals
    end

    private

    attr_reader :conn_opts
    attr_accessor :format_delimiter

    def setup
      ActiveRecord::Base.establish_connection @conn_opts
      Foreigner.load
    end

    def create_basics
      SO2DB::CreateBasicTables.new.up
    end

    def import_data(dir)
      files = Dir.entries(dir).delete_if { |x| !x.end_with? 'xml' }
      files.each do |f|
        f = Formatter.new(File.join(dir, f), @format_delimiter)
        import_stream f
      end
    end

    def create_relations
      SO2DB::CreateRelationships.new.up
    end

    def create_optionals
      SO2DB::CreateOptionals.new.up
    end

    def create_optional_relations
      SO2DB::CreateOptionalRelationships.new.up
    end

  end
end

require 'so2db/formatter'
require 'so2db/migrations'
require 'so2db/models'
