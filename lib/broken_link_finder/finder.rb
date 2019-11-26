# frozen_string_literal: true

module BrokenLinkFinder
  DEFAULT_MAX_THREADS = 100

  # Alias for BrokenLinkFinder::Finder.new.
  def self.new(sort: :page, max_threads: DEFAULT_MAX_THREADS)
    Finder.new(sort: sort, max_threads: max_threads)
  end

  class Finder
    attr_reader :sort, :broken_links, :ignored_links, :total_links_crawled, :max_threads

    # Creates a new Finder instance.
    def initialize(sort: :page, max_threads: BrokenLinkFinder::DEFAULT_MAX_THREADS)
      raise "Sort by either :page or :link, not #{sort}" \
      unless %i[page link].include?(sort)

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
      @url_map             = {}
    end

    # Finds broken links within a single page and appends them to the
    # @broken_links array. Returns true if at least one broken link was found.
    # Access the broken links afterwards with Finder#broken_links.
    def crawl_url(url)
      clear_links

      @url = url.to_url
      doc = @crawler.crawl(@url)

      # Ensure the given page url is valid.
      raise "Invalid or broken URL: #{@url}" unless doc

      # Get all page links and determine which are broken.
      find_broken_links(doc)
      retry_broken_links

      sort_links
      set_total_links_crawled

      @broken_links.any?
    end

    # Finds broken links within an entire site and appends them to the
    # @broken_links array. Returns a tuple containing a Boolean of true if
    # at least one broken link was found and an Array of all pages crawled.
    # Access the broken links afterwards with Finder#broken_links.
    def crawl_site(url)
      clear_links

      @url          = url.to_url
      pool          = Thread.pool(@max_threads)
      crawled_pages = []

      # Crawl the site's HTML web pages looking for links.
      externals = @crawler.crawl_site(@url) do |doc|
        crawled_pages << doc.url
        next unless doc

        # Start a thread for each page, checking for broken links.
        pool.process { find_broken_links(doc) }
      end

      # Ensure the given website url is valid.
      raise "Invalid or broken URL: #{@url}" unless externals

      # Wait for all threads to finish.
      pool.shutdown
      retry_broken_links

      sort_links
      set_total_links_crawled

      [@broken_links.any?, crawled_pages.uniq]
    end

    # Pretty prints the link report into a stream e.g. STDOUT or a file,
    # anything that respond_to? :puts. Defaults to STDOUT.
    # Returns true if there were broken links and vice versa.
    def report(
      stream = STDOUT,
      type: :text,
      broken_verbose: true,
      ignored_verbose: false
    )
      klass = case type
              when :text
                BrokenLinkFinder::TextReporter
              when :html
                BrokenLinkFinder::HTMLReporter
              else
                raise "type: must be :text or :html, not: :#{type}"
              end

      reporter = klass.new(stream, @url, @sort, @broken_links, @ignored_links)
      reporter.call(
        broken_verbose:  broken_verbose,
        ignored_verbose: ignored_verbose
      )

      @broken_links.any?
    end

    private

    # Finds which links are unsupported or broken and records the details.
    def find_broken_links(page)
      links = get_supported_links(page)

      # Iterate over the supported links checking if they're broken or not.
      links.each do |link|
        # Check if the link has already been processed previously.
        next if @all_intact_links.include?(link)

        if @all_broken_links.include?(link)
          append_broken_link(page.url, link)
          next
        end

        # The link hasn't been processed before so we crawl it.
        link_doc = crawl_link(page, link)

        # Determine if the crawled link is broken or not.
        if link_broken?(link_doc)
          append_broken_link(page.url, link, doc: page)
        else
          @lock.synchronize { @all_intact_links << link }
        end
      end

      nil
    end

    # Implements a retry mechanism for each of the broken links found.
    # Removes any broken links found to be working OK.
    def retry_broken_links
      sleep(0.5) # Give the servers a break, then retry the links.

      @url_map.each do |link, href|
        doc = @crawler.crawl(href)
        remove_broken_link(link) unless link_broken?(doc)
      end
    end

    # Report and reject any non supported links. Any link that is absolute and
    # doesn't start with 'http' is unsupported e.g. 'mailto:blah' etc.
    def get_supported_links(doc)
      doc.all_links
         .reject do |link|
           if link.is_absolute? && !link.start_with?('http')
             append_ignored_link(doc.url, link)
             true
           end
         end
    end

    # Makes the link absolute and crawls it, returning its Wgit::Document.
    def crawl_link(doc, link)
      link = link.prefix_base(doc)
      @crawler.crawl(link)
    end

    # Return if the crawled link is broken or not.
    def link_broken?(doc)
      doc.nil? || @crawler.last_response.not_found? || has_broken_anchor(doc)
    end

    # Returns true if the link is/contains a broken anchor/fragment.
    def has_broken_anchor(doc)
      raise 'link document is nil' unless doc

      fragment = doc.url.fragment
      return false if fragment.nil? || fragment.empty?

      doc.xpath("//*[@id='#{fragment}']").empty?
    end

    # Append key => [value] to @broken_links.
    # If doc: is provided then the link will be recorded in absolute form.
    def append_broken_link(url, link, doc: nil)
      key, value = get_key_value(url, link)

      @lock.synchronize do
        @broken_links[key] = [] unless @broken_links[key]
        @broken_links[key] << value

        @all_broken_links  << link
      end

      @url_map[link] = link.prefix_base(doc) if doc
    end

    def remove_broken_link(link)
      if @sort == :page
        @broken_links.each { |_k, links| links.delete(link) }
        @broken_links.delete_if { |_k, links| links.empty? }
      else
        @broken_links.delete(link)
      end

      @all_broken_links.delete(link)
    end

    # Append key => [value] to @ignored_links.
    def append_ignored_link(url, link)
      key, value = get_key_value(url, link)

      @lock.synchronize do
        @ignored_links[key] = [] unless @ignored_links[key]
        @ignored_links[key] << value
      end
    end

    # Returns the correct key value depending on the @sort type.
    # @sort == :page ? [url, link] : [link, url]
    def get_key_value(url, link)
      case @sort
      when :page
        [url, link]
      when :link
        [link, url]
      else
        raise "Unsupported sort type: #{sort}"
      end
    end

    # Sort keys and values alphabetically.
    def sort_links
      @broken_links.values.map(&:uniq!)
      @ignored_links.values.map(&:uniq!)

      @broken_links  = @broken_links.sort_by  { |k, _v| k }.to_h
      @ignored_links = @ignored_links.sort_by { |k, _v| k }.to_h

      @broken_links.each  { |_k, v| v.sort! }
      @ignored_links.each { |_k, v| v.sort! }
    end

    # Sets and returns the total number of links crawled.
    def set_total_links_crawled
      @total_links_crawled = @all_broken_links.size + @all_intact_links.size
    end

    alias crawl_page crawl_url
    alias crawl_r    crawl_site
  end
end
