require 'minitest/unit'
require 'so2db'

class LookupTest < MiniTest::Unit::TestCase

  def test_lookup_badges
    assert_equal SO2DB::Models::Badge, SO2DB::Models::Lookup::find_class("Badges")
  end

  def test_required_attrs_badges
    attrs = SO2DB::Models::Lookup::get_required_attrs("Badges")
    assert_equal [ "Id", "UserId", "Name", "Date" ], attrs
  end

  def test_guid_capitalization
    attrs = SO2DB::Models::Lookup::get_required_attrs("PostHistory")
    assert attrs.include? 'RevisionGUID'
  end

end
