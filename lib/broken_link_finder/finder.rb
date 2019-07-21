require 'wgit'
require 'thread/pool'

module BrokenLinkFinder
  class Finder
    DEFAULT_MAX_THREADS = 30.freeze

    attr_reader :broken_links

    # Create a new Finder instance.
    def initialize(max_threads: DEFAULT_MAX_THREADS)
      @max_threads = max_threads
      @lock = Mutex.new
      @crawler = Wgit::Crawler.new
      @broken_links = {}
    end

    # Clear/empty the @broken_links Hash.
    def clear_broken_links
      @broken_links = {}
    end

    # Finds broken links within an entire site and appends them to the
    # @broken_links array. Returns a tuple containing a Boolean of true if
    # at least one broken link was found and an Array of all pages crawled.
    # Access the broken links with Finder#broken_links.
    def crawl_site(url)
      clear_broken_links
      url = Wgit::Url.new(url)
      pool = Thread.pool(@max_threads)
      crawled_pages = []

      @crawler.crawl_site(url) do |doc|
        # Ensure the given website url is valid.
        raise "Invalid URL: #{url}" if doc.url == url and doc.empty?

        # Ensure we only process each page once. For example, /about.html might
        # be linked to several times throughout the entire site.
        next if crawled_pages.include?(doc.url)
        crawled_pages << doc.url

        # Get all page links and determine which are broken.
        next unless doc
        pool.process { find_broken_links(doc) }
      end

      pool.shutdown
      [!@broken_links.empty?, crawled_pages]
    end

    # Finds broken links within a single page and appends them to the
    # @broken_links array. Returns true if at least one broken link was found.
    # Access the broken links with Finder#broken_links.
    def crawl_url(url)
      clear_broken_links
      url = Wgit::Url.new(url)

      # Ensure the given page url is valid.
      doc = @crawler.crawl_url(url)
      raise "Invalid URL: #{url}" unless doc

      # Get all page links and determine which are broken.
      find_broken_links(doc)

      !@broken_links.empty?
    end

    # Pretty prints the contents of broken_links into a stream e.g. Kernel
    # (STDOUT) or a file - anything that respond_to? :puts.
    # Returns true if there were broken links and vice versa.
    def pretty_print_broken_links(stream = Kernel)
      raise "stream must respond_to? :puts" unless stream.respond_to? :puts

      if @broken_links.empty?
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

    # Finds which links are broken and appends the details to @broken_links.
    def find_broken_links(doc)
      links = doc.internal_full_links + doc.external_links
      links.each do |link|
        link_doc = @crawler.crawl_url(link)
        if @crawler.last_response.is_a?(Net::HTTPNotFound) or
            link_doc.nil? or
            has_broken_anchor(link_doc)
          append_broken_link(doc.url, link)
        end
      end
    end

    # Returns true if the link is/contains a broken anchor.
    def has_broken_anchor(doc)
      raise "link document is nil" unless doc
      return false unless doc.url.anchor

      anchor = doc.url.anchor[1..-1] # Remove the # prefix.
      doc.xpath("//*[@id='#{anchor}']").empty?
    end

    # Append url => [link] to @broken_links.
    def append_broken_link(url, link)
      @lock.synchronize do
        unless @broken_links[url]
          @broken_links[url] = []
        end
        @broken_links[url] << link
      end
    end

    alias_method :crawl_page, :crawl_url
  end
end
