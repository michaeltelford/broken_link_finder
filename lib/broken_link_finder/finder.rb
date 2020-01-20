# frozen_string_literal: true

module BrokenLinkFinder
  DEFAULT_MAX_THREADS = 100

  # Alias for BrokenLinkFinder::Finder.new.
  def self.new(sort: :page, max_threads: DEFAULT_MAX_THREADS)
    Finder.new(sort: sort, max_threads: max_threads)
  end

  class Finder
    attr_reader :sort, :max_threads, :broken_links, :ignored_links, :crawl_stats

    # Creates a new Finder instance.
    def initialize(sort: :page, max_threads: BrokenLinkFinder::DEFAULT_MAX_THREADS)
      raise "Sort by either :page or :link, not #{sort}" \
      unless %i[page link].include?(sort)

      @sort        = sort
      @max_threads = max_threads
      @lock        = Mutex.new
      @crawler     = Wgit::Crawler.new

      reset_crawl
    end

    # Clear/empty the link collection Hashes.
    def reset_crawl
      @broken_links      = {}      # Used for mapping pages to broken links.
      @ignored_links     = {}      # Used for mapping pages to ignored links.
      @all_broken_links  = Set.new # Used to prevent crawling a broken link twice.
      @all_intact_links  = Set.new # Used to prevent crawling an intact link twice.
      @all_ignored_links = Set.new # Used for building crawl statistics.
      @broken_link_map   = {}      # Maps a link to its absolute form.
      @crawl_stats       = {}      # Records crawl stats e.g. duration etc.
    end

    # Finds broken links within a single page and appends them to the
    # @broken_links array. Returns true if at least one broken link was found.
    # Access the broken links afterwards with Finder#broken_links.
    def crawl_url(url)
      reset_crawl

      start = Time.now
      url   = url.to_url
      doc   = @crawler.crawl(url)

      # Ensure the given page url is valid.
      raise "Invalid or broken URL: #{url}" unless doc

      # Get all page links and determine which are broken.
      find_broken_links(doc)
      retry_broken_links

      sort_links
      set_crawl_stats(url: url, pages_crawled: [url], start: start)

      @broken_links.any?
    end

    # Finds broken links within an entire site and appends them to the
    # @broken_links array. Returns true if at least one broken link was found.
    # Access the broken links afterwards with Finder#broken_links.
    def crawl_site(url)
      reset_crawl

      start   = Time.now
      url     = url.to_url
      pool    = Thread.pool(@max_threads)
      crawled = Set.new

      # Crawl the site's HTML web pages looking for links.
      externals = @crawler.crawl_site(url) do |doc|
        crawled << doc.url
        next unless doc

        # Start a thread for each page, checking for broken links.
        pool.process { find_broken_links(doc) }
      end

      # Ensure the given website url is valid.
      raise "Invalid or broken URL: #{url}" unless externals

      # Wait for all threads to finish.
      pool.shutdown
      retry_broken_links

      sort_links
      set_crawl_stats(url: url, pages_crawled: crawled.to_a, start: start)

      @broken_links.any?
    end

    # Pretty prints the link report into a stream e.g. STDOUT or a file,
    # anything that respond_to? :puts. Defaults to STDOUT.
    def report(stream = STDOUT,
               type: :text, broken_verbose: true, ignored_verbose: false)
      klass = case type
              when :text
                BrokenLinkFinder::TextReporter
              when :html
                BrokenLinkFinder::HTMLReporter
              else
                raise "type: must be :text or :html, not: :#{type}"
              end

      reporter = klass.new(stream, @sort, @broken_links,
                           @ignored_links, @broken_link_map, @crawl_stats)
      reporter.call(broken_verbose:  broken_verbose,
                    ignored_verbose: ignored_verbose)
    end

    private

    # Finds which links are unsupported or broken and records the details.
    def find_broken_links(page)
      links = get_supported_links(page)

      # Iterate over the supported links checking if they're broken or not.
      links.each do |link|
        # Skip if the link has been processed previously.
        next if @all_intact_links.include?(link)

        if @all_broken_links.include?(link)
          append_broken_link(page.url, link) # Record on which page.
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

      @broken_link_map.select! do |link, href|
        doc = @crawler.crawl(href.dup)
        if link_broken?(doc)
          true
        else
          remove_broken_link(link)
          false
        end
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

    # Make the link absolute and crawl it, returning its Wgit::Document.
    def crawl_link(doc, link)
      link = link.prefix_base(doc)
      @crawler.crawl(link.dup)
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

        @all_broken_links << link

        @broken_link_map[link] = link.prefix_base(doc) if doc
      end
    end

    # Remove the broken_link from the necessary collections.
    def remove_broken_link(link)
      @lock.synchronize do
        if @sort == :page
          @broken_links.each { |_k, links| links.delete(link) }
          @broken_links.delete_if { |_k, links| links.empty? }
        else
          @broken_links.delete(link)
        end

        @all_broken_links.delete(link)
        @all_intact_links << link
      end
    end

    # Append key => [value] to @ignored_links.
    def append_ignored_link(url, link)
      key, value = get_key_value(url, link)

      @lock.synchronize do
        @ignored_links[key] = [] unless @ignored_links[key]
        @ignored_links[key] << value

        @all_ignored_links << link
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
    def set_crawl_stats(url:, pages_crawled:, start:)
      @crawl_stats[:url]               = url
      @crawl_stats[:pages_crawled]     = pages_crawled
      @crawl_stats[:num_pages]         = pages_crawled.size
      @crawl_stats[:num_links]         = (
        @all_broken_links.size + @all_intact_links.size + @all_ignored_links.size
      )
      @crawl_stats[:num_broken_links]  = @all_broken_links.size
      @crawl_stats[:num_intact_links]  = @all_intact_links.size
      @crawl_stats[:num_ignored_links] = @all_ignored_links.size
      @crawl_stats[:duration]          = Time.now - start
    end

    alias crawl_page crawl_url
    alias crawl_r    crawl_site
  end
end
