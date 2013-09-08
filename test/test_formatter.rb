require 'minitest/autorun'
require 'so2db'

class FormatterTest < MiniTest::Unit::TestCase

  def setup
    @delimiter = ','
    @attributes = [ 'Id', 'UserId', 'Name', 'Text', 'Date', 'SomethingElse' ]
    @formatter = SO2DB::Formatter.new @attributes, @delimiter
    @xml = <<-eoxml
<data>
<fake-row id="3"/>
<row Id="1" UserId="2" Name="Autobiographer" Date="2010-07-20T19:07:22.990" Text="asdf" />
</data>
    eoxml
  end

  def test_initialize
    assert_equal @delimiter, @formatter.delimiter
    assert_equal @attributes, @formatter.attributes
  end

  def test_format
    r, w = IO.pipe

    @formatter.format(@xml, w)
    actual = r.gets

    expected = "1,2,Autobiographer,asdf,2010-07-20T19:07:22.990,\n"

    assert_equal expected, actual
  end

end
