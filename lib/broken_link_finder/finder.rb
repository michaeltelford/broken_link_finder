require 'wgit'

module BrokenLinkFinder
  class Finder
    attr_reader :url, :broken_links

    # Create a new Finder instance.
    def initialize(url)
      @broken_links = {}
      @url = Wgit::Url.new(url)
      @crawler = Wgit::Crawler.new(@url)
    end

    # Clear/empty the @broken_links Hash.
    def clear_broken_links
      @broken_links = {}
    end

    # Finds broken urls within an entire site and appends them to the
    # @broken_links array.
    # We deliberately don't keep a record of valid links because we are 
    # sacrificing bandwidth and runtime speed for a lower memory footprint. 
    # This will benefit large site with potentially thousands of links. 
    def crawl_site
      @crawler.crawl_site do |doc|
        crawl_url(doc.url)
      end
    end

    # Finds broken urls within a single page and appends them to the
    # @broken_links array.
    def crawl_url(url = @url)
      doc = @crawler.crawl_url(url)
      raise "Invalid URL: #{url}" unless doc
      links = doc.external_links + doc.internal_full_links
      get_broken_links(doc.url, links)
    end

    # Pretty prints the contents of broken_links into a stream e.g. Kernel
    # (STDOUT) or a file. 
    # Returns true if there were broken links and vice versa. 
    def pretty_print_broken_links(stream = Kernel)
      raise "stream must respond_to? :puts" unless stream.respond_to? :puts
      
      if (@broken_links.empty?)
        stream.puts("Good news, there are no broken links for #{@url}")
        false
      else
        stream.puts("Below is a breakdown of the different pages and their \
broken links for the site #{@url}")
        stream.puts("")

        @broken_links.each do |page, links|
          stream.puts("The following broken links exist in #{page}:")
          links.each do |link|
            stream.puts(link)
          end
          stream.puts("")
        end
        true
      end
    end

    private

    # Find which links are broken and append the details to @broken_links.
    def get_broken_links(url, links)
      links.each do |link|
        ok = @crawler.crawl_url(link)
        if not ok # a.k.a. if the link is broken...
          unless @broken_links[url]
            @broken_links[url] = []
          end
          @broken_links[url] << link
        end
      end
    end

    alias_method :crawl_page, :crawl_url
  end
end
