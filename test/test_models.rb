require 'minitest/autorun'
require 'so2db'

class LookupTest < Minitest::Test
  include Rake::DSL

  def test_lookup_badges
    assert_equal SO2DB::Models::Badge, SO2DB::Models::Lookup::find_class("badges")
  end

  def test_required_attrs_badges
    attrs = SO2DB::Models::Lookup::get_required_attrs("badges")
    assert_equal [ "Id", "UserId", "Name", "Date", "Class", "TagBased" ], attrs
  end

  def test_guid_capitalization
    attrs = SO2DB::Models::Lookup::get_required_attrs("posthistory")
    assert(attrs.include? 'RevisionGUID')
  end
end
