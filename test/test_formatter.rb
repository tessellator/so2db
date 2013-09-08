require 'minitest/autorun'
require 'so2db'

class FormatterTest < MiniTest::Unit::TestCase

  def setup
    @formatter = SO2DB::Formatter.new("/tmp/badges.xml")
  end

  def test_initializer_with_default_args
    skip

    f = SO2DB::Formatter.new
    assert_equal '', f.instance_variable_get(:@path)
    assert_equal 11.chr.to_s, f.instance_variable_get(:@delimiter)
  end

  def test_initializer_with_provided_args
    skip

    path = '/my/test/path'
    delimiter = 12.chr.to_s
    f = SO2DB::Formatter.new(path, delimiter)

    assert_equal path, f.instance_variable_get(:@path)
    assert_equal delimiter, f.instance_variable_get(:@delimiter)
  end

  def test_format
    skip

    file = "file"
    outstream = "outstream"
    attrs = [ :a, :b, :c ]
    SO2DB::Models::Lookup.expects(:get_required_attrs).with("badges").once.returns(attrs)
    File.expects(:open).with("/tmp/badges.xml").once.returns(file)
    @formatter.expects(:format_from_stream).with(file, attrs, outstream).once.returns("x")

    result = @formatter.format(outstream)
    assert_equal "x", result
  end

  def test_format_from_stream
    skip

    x = <<-eoxml
<data>
<fake-row id="3"/>
<row Id="1" UserId="2" Name="Autobiographer" Date="2010-07-20T19:07:22.990" />
</data>
    eoxml

    r, w = IO.pipe

    arr = [ "Id", "UserId", "Name", "Date", "Missing" ]
    @formatter.send(:format_from_stream, x, arr, w)

    values = [ '2010-07-20T19:07:22.990', '1', '', 'Autobiographer', '2' ]
    expected = values.join(11.chr.to_s) << "\n"
    actual = r.gets

    assert_equal expected, actual
  end

  def test_file_name
    skip

    assert_equal "badges.xml", @formatter.file_name
  end

  def test_value_str
    skip

    assert_equal "badges(date,id,name,user_id)", @formatter.value_str
  end

  def create_node_stub(name, node_type)
    obj = mock()
    obj.stubs(:name).returns(name)
    obj.stubs(:node_type).returns(node_type)

    obj
  end

  def test_element_start_with_good_values
    skip

    node = create_node_stub("row", Nokogiri::XML::Reader::TYPE_ELEMENT)
    assert @formatter.send(:element_start?, node)
  end

  def test_element_start_with_invalid_type
    skip

    node = create_node_stub("row", Nokogiri::XML::Reader::TYPE_END_ELEMENT)
    assert_equal false, @formatter.send(:element_start?, node)
  end

  def test_element_start_with_invalid_name
    skip

    node = create_node_stub("badges", Nokogiri::XML::Reader::TYPE_ELEMENT)
    assert_equal false, @formatter.send(:element_start?, node)
  end

  def test_format_node
    skip

    node = mock()
    node.stubs(:attribute).with("Id").returns("1")
    node.stubs(:attribute).with("Name").returns("Anony Mous")

    @formatter.expects(:scrub).with("1").once.returns("1")
    @formatter.expects(:scrub).with("Anony Mous").once.returns("Anony Mous")

    result = @formatter.send(:format_node, node, [ "Id", "Name" ])

    assert_equal "1\vAnony Mous", result
  end

  def test_format_node_with_missing_attribute
    skip

    node = mock()
    node.stubs(:attribute).with("Id").returns("1")
    node.stubs(:attribute).with("Name").returns(nil)

    @formatter.expects(:scrub).once.with("1").returns("1")

    result = @formatter.send(:format_node, node, [ "Id", "Name" ])

    assert_equal "1\v", result
  end

  def test_scrub
    skip

    assert_equal '&lt;asdffdsa&gt;', @formatter.send(:scrub, "<asdf\nfdsa\r>")
  end

end

