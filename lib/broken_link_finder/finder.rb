require_relative 'reporter'
require 'wgit'
require 'thread/pool'
require 'set'

module BrokenLinkFinder
  # Alias for BrokenLinkFinder::Finder.new, don't use this if you want to
  # override the max_threads variable.
  def self.new(sort: :page)
    Finder.new(sort: sort)
  end

  class Finder
    DEFAULT_MAX_THREADS = 30.freeze

    attr_reader :broken_links, :ignored_links, :total_links_crawled

    # Creates a new Finder instance.
    def initialize(sort: :page, max_threads: DEFAULT_MAX_THREADS)
      unless [:page, :link].include?(sort)
        raise "sort by either :page or :link, not #{sort}"
      end

      @sort        = sort
      @max_threads = max_threads
      @lock        = Mutex.new
      @crawler     = Wgit::Crawler.new

      clear_links
    end

    # Clear/empty the link collection Hashes.
    def clear_links
      @broken_links        = {}
      @ignored_links       = {}
      @total_links_crawled = 0
      @all_broken_links    = Set.new
      @all_intact_links    = Set.new
    end

    # Finds broken links within a single page and appends them to the
    # @broken_links array. Returns true if at least one broken link was found.
    # Access the broken links with Finder#broken_links.
    def crawl_url(url)
      clear_links

      url = Wgit::Url.new(url)
      doc = @crawler.crawl_url(url)

      # Ensure the given page url is valid.
      raise "Invalid or broken URL: #{url}" unless doc

      # Get all page links and determine which are broken.
      find_broken_links(doc)

      sort_links
      set_total_links_crawled

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
      orig_doc = @crawler.crawl_site(url) do |doc|
        crawled_pages << doc.url
        next unless doc

        # Start a thread for each page, checking for broken links.
        pool.process { find_broken_links(doc) }
      end

      # Ensure the given website url is valid.
      raise "Invalid or broken URL: #{url}" if orig_doc.nil?

      # Wait for all threads to finish.
      pool.shutdown

      sort_links
      set_total_links_crawled

      [@broken_links.any?, crawled_pages.uniq]
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
      # Report and reject any non supported links.
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
        # Check if the link has already been processed previously.
        next if @all_intact_links.include?(link)

        if @all_broken_links.include?(link)
          append_broken_link(doc.url, link)
          next
        end

        # The link hasn't been processed before so we crawl it.
        link_url = get_absolute_link(doc, link)
        link_doc = @crawler.crawl_url(link_url)

        # Determine if the crawled link is broken or not.
        if @crawler.last_response.is_a?(Net::HTTPNotFound) or
            link_doc.nil? or
            has_broken_anchor(link_doc)
          append_broken_link(doc.url, link)
        else
          @lock.synchronize { @all_intact_links << link }
        end
      end

      nil
    end

    # Returns the link in absolute form so it can be crawled.
    def get_absolute_link(doc, link)
      if link.is_relative?
        doc.base_url(link: link).concat(link)
      else
        link
      end
    end

    # Returns true if the link is/contains a broken anchor.
    def has_broken_anchor(doc)
      raise "link document is nil" unless doc

      anchor = doc.url.anchor
      return false if anchor.nil? or anchor == '#'

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

        @all_broken_links  << link
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

    # Sets and returns the total number of links crawled.
    def set_total_links_crawled
      @total_links_crawled = @all_broken_links.size + @all_intact_links.size
    end

    alias_method :crawl_page, :crawl_url
    alias_method :pretty_print_link_summary, :pretty_print_link_report
  end
end
