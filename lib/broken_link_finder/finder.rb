require_relative 'reporter'
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

    # Creates a new Finder instance.
    def initialize(sort: :page, max_threads: DEFAULT_MAX_THREADS)
      unless [:page, :link].include?(sort)
        raise "sort by either :page or :link, not #{sort}"
      end
      @sort = sort
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

      sort_links
      @broken_links.any?
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

      pool.shutdown # Wait for all threads to finish.
      sort_links
      [@broken_links.any?, crawled_pages]
    end

    # Pretty prints the link report into a stream e.g. STDOUT or a file,
    # anything that respond_to? :puts. Defaults to STDOUT.
    # Returns true if there were broken links and vice versa.
    def pretty_print_link_report(
      stream = STDOUT,
      broken_verbose: true,
      ignored_verbose: false
    )
      reporter = BrokenLinkFinder::Reporter.new(
        stream, @sort, @broken_links, @ignored_links
      )
      reporter.pretty_print_link_report(
        broken_verbose: broken_verbose,
        ignored_verbose: ignored_verbose
      )

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

      nil
    end

    # Returns true if the link is/contains a broken anchor.
    def has_broken_anchor(doc)
      raise "link document is nil" unless doc

      anchor = doc.url.anchor
      return false unless anchor

      anchor = anchor[1..-1] if anchor.start_with?('#')
      doc.xpath("//*[@id='#{anchor}']").empty?
    end

    # Append key => [value] to @broken_links.
    def append_broken_link(url, link)
      key, value = get_key_value(url, link)
      @lock.synchronize do
        unless @broken_links[key]
          @broken_links[key] = []
        end
        @broken_links[key] << value
      end
    end

    # Append key => [value] to @ignored_links.
    def append_ignored_link(url, link)
      key, value = get_key_value(url, link)
      @lock.synchronize do
        unless @ignored_links[key]
          @ignored_links[key] = []
        end
        @ignored_links[key] << value
      end
    end

    # Returns the correct key value depending on the @sort type.
    # @sort == :page ? [url, link] : [link, url]
    def get_key_value(url, link)
      if @sort == :page
        [url, link]
      elsif @sort == :link
        [link, url]
      else
        raise "Unsupported sort type: #{sort}"
      end
    end

    # Sort keys and values alphabetically.
    def sort_links
      @broken_links = @broken_links.sort_by { |k, v| k }.to_h
      @ignored_links = @ignored_links.sort_by { |k, v| k }.to_h

      @broken_links.each { |k, v| v.sort! }
      @ignored_links.each { |k, v| v.sort! }
    end

    alias_method :crawl_page, :crawl_url
    alias_method :pretty_print_link_summary, :pretty_print_link_report
  end
end
