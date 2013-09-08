require 'nokogiri'

module SO2DB

  # Formats data from an XML text stream into another stream.
  class Formatter
    attr_reader :delimiter, :attributes

    # Infrastructure.  Do not call this from your code.
    def initialize(attributes, delimiter = 11.chr.to_s)
      @attributes = attributes
      @delimiter = delimiter
      @name = 'row'
    end

    def format(instream, outstream)
      Nokogiri::XML::Reader(instream).each do |node|
        outstream.puts format_node node if element_start? node
      end
    end

    private

    def element_start?(node)
      node.name == @name &&
        node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
    end

    def format_node(node)
      arr = attributes.map do |a|
        str = node.attribute(a)
        str ? scrub(str) : ''
      end

      arr.join(delimiter)
    end

    def scrub(str)
      str.gsub(/\n|\r/, '')
    end

  end
end

