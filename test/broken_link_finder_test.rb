require 'test_helper'

class BrokenLinkFinderTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::BrokenLinkFinder::VERSION
  end
end
