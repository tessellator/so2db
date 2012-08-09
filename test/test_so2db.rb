require 'test/unit'
require 'mocha'
require 'so2db'

class ImporterTest < Test::Unit::TestCase

  def test_import_data
    importer = SO2DB::Importer.new
    Dir.expects(:entries).once.with('/tmp').returns([ 'test.bak', 'test.xml' ])
    SO2DB::Formatter.expects(:new).once
              .with('/tmp/test.xml', 11.chr.to_s).returns('formatter')
    importer.expects(:import_stream).once.with('formatter')

    importer.send(:import_data, '/tmp')
  end

end
