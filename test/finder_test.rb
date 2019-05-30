require 'test_helper'

class FinderTest < TestHelper
  def setup
    @finder = Finder.new "https://motherfuckingwebsite.com/"
  end

  def test_find_broken_links
    skip
  end
end
