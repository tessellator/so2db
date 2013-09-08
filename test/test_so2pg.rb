require 'minitest/autorun'
require 'so2pg'

class PgImporterTest < MiniTest::Unit::TestCase

  def setup
    @importer = PgImporter.new(true, true, { :database => "dbname", :dir => "dir" })
  end

  def test_import_stream
    formatter = mock()
    formatter.stubs(:file_name).returns("file_name")
    formatter.expects(:value_str).once.returns('badges(id,name)')

    @importer.expects(:build_sql).once.with('badges(id,name)').returns("COPY...")
    @importer.expects(:build_cmd).once.with("COPY...").returns("cmd")
    @importer.stubs(:execute_cmd).returns('')
    @importer.expects(:execute_cmd).once.with("cmd", formatter).returns('')

    $stdout.stubs(:puts).returns('')

    @importer.send(:import_stream, formatter)
  end

  def test_build_sql
    exp = "COPY badges(id,name) FROM STDIN WITH (FORMAT csv, DELIMITER E'\x0B')"
    assert_equal exp, @importer.send(:build_sql, "badges(id,name)")
  end

  def test_build_cmd
    expected = "psql -d dbname -c \"COPY...\""
    actual = @importer.send(:build_cmd, "COPY...")

    assert_equal expected, actual
  end

  def test_build_cmd_sets_env_password
    importer = PgImporter.new(true, true, { :database => "dbname",
                                            :dir => "dir",
                                            :password => "asdf1234" })

    importer.send(:build_cmd, "COPY...")
    assert_equal "asdf1234", ENV['PGPASSWORD']
  end

  def test_execute_cmd
    strm = mock()
    formatter = mock()

    IO.expects(:popen).once.with("cmd", "r+").yields(strm)
    formatter.expects(:format).once.with(strm)
    strm.expects(:close_write).once

    @importer.send(:execute_cmd, "cmd", formatter)
  end

end

class PgOptionsParserTest < MiniTest::Unit::TestCase

  def test_all_options
    host = 'localhost'
    database = 'database_name'
    directory = 'data_directory'
    user = 'anony'
    password = 'mous'
    port = '1234'

    cmd = [ '-H', host, '-d', database, '-D', directory, '-u', user, 
            '-p', password, '-P', port, '-O', '-R' ]

    options = PgOptionsParser.parse(cmd)

    assert_equal host, options[:host]
    assert_equal database, options[:database]
    assert_equal directory, options[:dir]
    assert_equal user, options[:username]
    assert_equal password, options[:password]
    assert_equal port, options[:port]
    assert options[:optionals]
    assert options[:relationships]
  end

  def assert_help_displayed(cmd)
    $stdout.expects(:puts).returns('')
    options = PgOptionsParser.parse(cmd)

    assert_nil options
  end

  def test_options_without_database
    assert_help_displayed [ '-D', 'data_dir' ]
  end

  def test_options_without_data_dir
    assert_help_displayed [ '-d', 'database_name' ]
  end

  def test_options_with_help
    assert_help_displayed [ '-D', 'data_dir', '-d', 'database_name', '-h' ]
  end

  def test_options_without_optionals
    cmd = [ '-D', 'data_dir', '-d', 'database_name', '-R' ]
    options = PgOptionsParser.parse(cmd)

    assert options[:relationships]
    assert !options[:optionals]
  end

  def test_options_without_relationships
    cmd = [ '-D', 'data_dir', '-d', 'database_name', '-O' ]
    options = PgOptionsParser.parse(cmd)

    assert !options[:relationships]
    assert options[:optionals]
  end

end
