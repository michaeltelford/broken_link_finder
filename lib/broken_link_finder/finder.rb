require 'wgit'
require 'thread/pool'

module BrokenLinkFinder
  # Alias for BrokenLinkFinder::Finder.new, don't use this if you want to
  # override the max_threads variable.
  def self.new
    Finder.new
  end

  class Finder
    DEFAULT_MAX_THREADS = 30.freeze

    attr_reader :broken_links, :ignored_links

    # Create a new Finder instance.
    def initialize(max_threads: DEFAULT_MAX_THREADS)
      @max_threads = max_threads
      @lock = Mutex.new
      @crawler = Wgit::Crawler.new
      clear_links
    end

    # Clear/empty the link collection Hashes.
    def clear_links
      @broken_links = {}
      @ignored_links = {}
    end

    # Finds broken links within an entire site and appends them to the
    # @broken_links array. Returns a tuple containing a Boolean of true if
    # at least one broken link was found and an Array of all pages crawled.
    # Access the broken links with Finder#broken_links.
    def crawl_site(url)
      clear_links
      url = Wgit::Url.new(url)
      pool = Thread.pool(@max_threads)
      crawled_pages = []

      # Crawl the site's HTML web pages looking for links.
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
      [@broken_links.any?, crawled_pages]
    end

    # Finds broken links within a single page and appends them to the
    # @broken_links array. Returns true if at least one broken link was found.
    # Access the broken links with Finder#broken_links.
    def crawl_url(url)
      clear_links
      url = Wgit::Url.new(url)

      # Ensure the given page url is valid.
      doc = @crawler.crawl_url(url)
      raise "Invalid URL: #{url}" unless doc

      # Get all page links and determine which are broken.
      find_broken_links(doc)

      @broken_links.any?
    end

    # Pretty prints the link summary into a stream e.g. Kernel
    # (STDOUT) or a file - anything that respond_to? :puts.
    # Returns true if there were broken links and vice versa.
    def pretty_print_link_summary(stream = Kernel)
      raise "stream must respond_to? :puts" unless stream.respond_to? :puts

      # Broken link summary.
      if @broken_links.empty?
        stream.puts("Good news, there are no broken links!")
        stream.puts("")
      else
        stream.puts("Below is a breakdown of the different pages and their \
broken links...")
        stream.puts("")

        @broken_links.each do |page, links|
          stream.puts("The following broken links exist on #{page}:")
          links.each do |link|
            stream.puts(link)
          end
          stream.puts("")
        end
      end

      # Ignored link summary.
      if @ignored_links.any?
        stream.puts("Below is a breakdown of the non supported links found, \
you should check these manually:")
        stream.puts("")

        @ignored_links.each do |page, links|
          stream.puts("The following links were ignored on #{page}:")
          links.each do |link|
            stream.puts(link)
          end
          stream.puts("")
        end
      end

      @broken_links.any?
    end

    private

    # Finds which links are unsupported or broken and records the details.
    def find_broken_links(doc)
      # Process the Document's links before checking if they're broke.
      links = doc.all_links.
        reject do |link|
          if !link.is_relative? and !link.start_with?('http')
            append_ignored_link(doc.url, link)
            true
          end
        end.
        uniq

      # Iterate over the supported links checking if they're broken or not.
      links.each do |link|
        link_url = link.is_relative? ? doc.url.to_base.concat(link) : link
        link_doc = @crawler.crawl_url(link_url)

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

    # Append url => [link] to @ignored_links.
    def append_ignored_link(url, link)
      @lock.synchronize do
        unless @ignored_links[url]
          @ignored_links[url] = []
        end
        @ignored_links[url] << link
      end
    end

    alias_method :crawl_page, :crawl_url
  end
end
