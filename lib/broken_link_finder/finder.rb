require 'wgit'

module BrokenLinkFinder
  class Finder
    attr_reader :broken_links

    # Create a new Finder instance.
    def initialize
      @broken_links = {}
      @crawler = Wgit::Crawler.new
    end

    # Clear/empty the @broken_links Hash.
    def clear_broken_links
      @broken_links = {}
    end

    # Finds broken links within an entire site and appends them to the
    # @broken_links array.
    def crawl_site(url)
      clear_broken_links
      url = Wgit::Url.new(url)
      crawled_pages = []

      @crawler.crawl_site(url) do |doc|
        # Ensure the given website url is valid.
        raise "Invalid URL: #{url}" if doc.url == url and doc.empty?

        # Ensure we only process each page once.
        next if crawled_pages.include?(doc.url)
        crawled_pages << doc.url

        # Get all page links and determine which are broken.
        next unless doc
        links = doc.internal_full_links + doc.external_links
        find_broken_links(doc.url, links)
      end

      !@broken_links.empty?
    end

    # Finds broken links within a single page and appends them to the
    # @broken_links array.
    def crawl_url(url)
      clear_broken_links
      url = Wgit::Url.new(url)

      # Ensure the given page url is valid.
      doc = @crawler.crawl_url(url)
      raise "Invalid URL: #{url}" unless doc

      # Get all page links and determine which are broken.
      links = doc.internal_full_links + doc.external_links
      find_broken_links(url, links)

      !@broken_links.empty?
    end

    # Pretty prints the contents of broken_links into a stream e.g. Kernel
    # (STDOUT) or a file. 
    # Returns true if there were broken links and vice versa. 
    def pretty_print_broken_links(stream = Kernel)
      raise "stream must respond_to? :puts" unless stream.respond_to? :puts
      
      if (@broken_links.empty?)
        stream.puts("Good news, there are no broken links!")
        false
      else
        stream.puts("Below is a breakdown of the different pages and their \
broken links...")
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

    # Finds which links are broken and append the details to @broken_links.
    def find_broken_links(url, links)
      links.each do |link|
        ok = @crawler.crawl_url(link)
        if not ok # a.k.a. if the link is broken...
          append_broken_link(url, link)
        end
      end
    end

    # Append url => [link] to @broken_links.
    def append_broken_link(url, link)
      unless @broken_links[url]
        @broken_links[url] = []
      end
      @broken_links[url] << link
    end

    alias_method :crawl_page, :crawl_url
  end
end
