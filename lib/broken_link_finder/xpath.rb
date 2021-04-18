# frozen_string_literal: true

module BrokenLinkFinder
  # Extract all the Document's <body> links e.g. <a>, <img>, <script> etc.
  DEFAULT_LINK_XPATH = '/html/body//*/@href | /html/body//*/@src'

  @link_xpath = DEFAULT_LINK_XPATH

  class << self
    # The xpath used to extract links from a crawled page.
    # Can be overridden as required.
    attr_accessor :link_xpath
  end
end
