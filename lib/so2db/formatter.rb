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


require 'active_support/inflector'
require 'nokogiri'
require 'cgi'

module SO2DB

  # Formats data from one stream into another stream.
  class Formatter

    # Infrastructure.  Do not call this from your code.
    def initialize(path = '', delimiter = 11.chr.to_s, lookup = Models::Lookup.new)
      @delimiter = delimiter
      @path = path
      @lookup = lookup
      @name = 'row'
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
      req_attrs = @lookup.get_required_attrs(file)

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
      o = @lookup.find_class(file)

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

