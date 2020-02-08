# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'broken_link_finder'
require 'maxitest/autorun'
require 'maxitest/threads' # Fail on orphaned threads.
require 'byebug'           # Call `byebug` to debug tests.
require_relative 'webmock' # Mock HTTP responses for tests.

class TestHelper < Minitest::Test
  include BrokenLinkFinder
end
