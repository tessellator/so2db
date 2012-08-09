require 'test/unit'
require 'so2db'

class LookupTest < Test::Unit::TestCase
  include Rake::DSL

  def test_lookup_badges
    assert_equal SO2DB::Models::Badge, SO2DB::Models::Lookup::find_class("badges")
  end

  def test_required_attrs_badges
    attrs = SO2DB::Models::Lookup::get_required_attrs("badges")
    assert_equal [ "Id", "UserId", "Name", "Date" ], attrs
  end

  def test_guid_capitalization
    attrs = SO2DB::Models::Lookup::get_required_attrs("posthistory")
    assert_block { attrs.include? 'RevisionGUID' }
  end
end
