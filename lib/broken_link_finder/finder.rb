require 'wgit'

module BrokenLinkFinder
  class Finder
    include Wgit

    attr_reader :url, :broken_links

    def initialize(url)
      @url = Url.new(url)
      @broken_links = {}
      @crawler = Crawler.new(@url)
    end

    # Finds and appends broken links to the broken_links array.
    # We deliberately don't keep a record of valid links because we are 
    # sacrificing bandwidth and runtime speed for a lower memory footprint. 
    # This will benefit large site with potentially thousands of links. 
    def crawl_site
      @crawler.crawl_site do |doc|
        puts "Crawling #{doc.url}..."
        links = doc.external_links + doc.internal_full_links
        get_broken_links(doc.url, links)
      end
    end

    def get_broken_links(url, links)
      links.each do |link|
        html = @crawler.crawl_url(link)
        if not html # If anything other than 200 - OK.
          unless broken_links[url]
            broken_links[url] = []
          end
          broken_links[url] << link
        end
      end
    end

    # Pretty prints the contents of broken_links into a stream e.g. Kernel
    # (STDOUT) or a file. 
    # Returns true if there were broken links and vice versa. 
    def pretty_print_broken_links(stream = Kernel)
      raise "stream must respond_to? :puts" unless stream.respond_to? :puts
      
      if (broken_links.empty?)
        stream.puts "Good news, there are no broken links for #{url}"
        false
      else
        stream.puts "Below is a breakdown of the different pages and their \
broken links for the site #{url}"
        stream.puts ""

        broken_links.each do |page, links|
          stream.puts "The following broken links exist in #{page}:"
          links.each do |link|
            stream.puts link
          end
          stream.puts ""
        end
        true
      end
    end
  end
end
