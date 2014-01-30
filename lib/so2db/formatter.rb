require 'active_support/inflector'
require 'nokogiri'
require 'cgi'

module SO2DB

  # Formats data from one stream into another stream.
  class Formatter

    # Infrastructure.  Do not call this from your code.
    def initialize(path = '', delimiter = 11.chr.to_s)
      @delimiter = delimiter
      @path = path
      @name = "row"
    end

    # Formats a file and prints the formatted output to the outstream.
    #
    # The output is performed via a 'puts' method.
    #
    # Example:
    #   >> f = get_formatter  # assumed to be provided to you
    #   >> cmd = get_cmd      # some shell command that accepts piped input
    #   >> IO.popen(cmd, 'r+') do |s| 
    #   >>   formatter.format(s)
    #   >>   s.close_write
    #   >> end
    def format(outstream)
      file = File.basename(@path, '.*')
      req_attrs = Models::Lookup::get_required_attrs(file)

      format_from_stream(File.open(@path), req_attrs, outstream)
    end

    def file_name
      File.basename(@path)
    end

    # Returns a string containing the data type and individual fields provided
    # through formatting. The fields are sorted alphabetically.
    #
    # This method is useful for building SQL statements for the formatted data.
    #
    # Example:
    #   >> f = get_formatter_for_badges # formatter should be provided to you
    #   >> puts f.value_str
    #   => badges(id,date,name,user_id)
    def value_str
      file = File.basename(@path, '.*')
      o = Models::Lookup::find_class(file)

      table = o.table_name
      values = o.exported_fields.sort.join(",")

      "#{table}(#{values})"
    end

    private
    def format_from_stream(instream, required_attrs, outstream)
      reader = Nokogiri::XML::Reader(instream)
      required_attrs.sort!

      reader.each do |node|
        outstream.puts format_node(node, required_attrs) if element_start? node
      end
    end

    def element_start?(node)
      node.name == @name &&
        node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
    end

    def format_node(node, attrs)
      arr = attrs.map do |a|
        str = node.attribute(a)
        str ? scrub(str) : ''
      end

      arr.join(@delimiter)
    end

    def scrub(str)
      s = CGI::escapeHTML(str)
      s.gsub!(/\n|\r/, '')

      s
    end

  end
end

