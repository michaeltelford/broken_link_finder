# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
$VERBOSE = nil # Suppress ruby warnings during the test run.

require 'broken_link_finder'
require 'maxitest/autorun'
# TODO: Uncomment when fixed: https://github.com/typhoeus/typhoeus/issues/648
# require 'maxitest/threads' # Fail on orphaned threads.
require 'byebug'           # Call `byebug` to debug tests.
require_relative 'webmock' # Mock HTTP responses for tests.

class TestHelper < Minitest::Test
  include BrokenLinkFinder
end
