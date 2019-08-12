require 'broken_link_finder'
require 'benchmark'
require 'memory_profiler'

url = ARGV[0] || "http://txti.es"
finder = BrokenLinkFinder::Finder.new

puts Benchmark.measure { finder.crawl_page url }
puts Benchmark.measure { finder.crawl_site url }

# http://txti.es
# Pre  threading: 17.591528
# Post threading: 7.508828 :-)

# http://txti.es
# Page: 9.526981
# Site: 9.732416
# Multi-threading crawl_site now yields the same time as a single page.
