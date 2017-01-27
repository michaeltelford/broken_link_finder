require 'test_helper'

class FinderTest < Minitest::Test
  def setup
    @finder = Finder.new()
  end

  def test_find_broken_links
    refute_nil ::BrokenLinkFinder::VERSION
  end
end
