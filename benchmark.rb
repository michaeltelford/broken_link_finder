require_relative './lib/broken_link_finder'
require 'benchmark'
require 'memory_profiler'

url = ARGV[0] || 'http://txti.es'
finder = BrokenLinkFinder::Finder.new

# puts Benchmark.measure { finder.crawl_page url }
puts Benchmark.measure { finder.crawl_site url }
puts "Links crawled: #{finder.total_links_crawled}"

# http://txti.es page crawl
# Pre  threading: 17.5 seconds
# Post threading: 7.5  seconds

# http://txti.es post threading - page vs site crawl
# Page: 9.526981
# Site: 9.732416
# Multi-threading crawl_site now yields the same time as a single page

# https://meos.ch/ site crawl - post all link recording functionality
# Pre:  608 seconds with 7665 links crawled
# Post: 355 seconds with 1099 links crawled
