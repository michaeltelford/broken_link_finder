require 'helpers/test_helper'

class VersionTest < TestHelper
  def test_that_it_has_a_version_number
    refute_nil BrokenLinkFinder::VERSION
  end
end
