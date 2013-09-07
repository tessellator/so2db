require 'minitest/autorun'
require 'so2db'

class LookupTest < MiniTest::Unit::TestCase

  def setup
    @lookup = SO2DB::Models::Lookup.new
  end

  def test_lookup_badges
    assert_equal SO2DB::Models::Badge, @lookup.find_class("badges")
  end

  def test_required_attrs_badges
    attrs = @lookup.get_required_attrs("badges")
    assert_equal [ "Id", "UserId", "Name", "Date" ], attrs
  end

  def test_guid_capitalization
    attrs = @lookup.get_required_attrs("posthistory")
    assert attrs.include? 'RevisionGUID'
  end

end
