$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'broken_link_finder'
require 'minitest/autorun'
require 'byebug' # Call `byebug` to debug tests.

class TestHelper < Minitest::Test
  include BrokenLinkFinder
end
