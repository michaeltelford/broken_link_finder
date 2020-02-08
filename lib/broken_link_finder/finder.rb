# frozen_string_literal: true

module BrokenLinkFinder
  DEFAULT_MAX_THREADS = 100 # Used by Finder#crawl_site.
  SERVER_WAIT_TIME    = 0.5 # Used by Finder#retry_broken_links.

  # Alias for BrokenLinkFinder::Finder.new.
  def self.new(sort: :page, max_threads: DEFAULT_MAX_THREADS)
    Finder.new(sort: sort, max_threads: max_threads)
  end

  # Class responsible for finding broken links on a page or site.
  class Finder
    # The collection key - either :page or :link.
    attr_reader :sort

    # The max number of threads created during #crawl_site - one thread per page.
    attr_reader :max_threads

    # Returns a new Finder instance.
    def initialize(sort: :page, max_threads: DEFAULT_MAX_THREADS)
      raise "Sort by either :page or :link, not #{sort}" \
      unless %i[page link].include?(sort)

      @sort        = sort
      @max_threads = max_threads
      @crawler     = Wgit::Crawler.new
      @manager     = BrokenLinkFinder::LinkManager.new(@sort)
    end

    # Returns the current broken links.
    def broken_links
      @manager.broken_links
    end

    # Returns the current ignored links.
    def ignored_links
      @manager.ignored_links
    end

    # Returns the current crawl stats.
    def crawl_stats
      @manager.crawl_stats
    end

    # Finds broken links within a single page and records them.
    # Returns true if at least one broken link was found.
    # Access the broken links afterwards with Finder#broken_links.
    def crawl_url(url)
      @manager.empty

      start = Time.now
      url   = url.to_url

      # We dup the url to avoid recording any redirects.
      doc = @crawler.crawl(url.dup)

      # Ensure the given page url is valid.
      raise "Invalid or broken URL: #{url}" unless doc

      # Get all page links and determine which are broken.
      find_broken_links(doc)
      retry_broken_links

      @manager.sort
      @manager.tally(url: url, pages_crawled: [url], start: start)

      broken_links.any?
    end

    # Finds broken links within an entire site and records them.
    # Returns true if at least one broken link was found.
    # Access the broken links afterwards with Finder#broken_links.
    def crawl_site(url, allow_paths: nil, disallow_paths: nil)
      @manager.empty

      start   = Time.now
      url     = url.to_url
      pool    = Thread.pool(@max_threads)
      crawled = Set.new

      # Crawl the site's HTML web pages looking for links.
      # We dup the url to avoid recording any redirects.
      paths = { allow_paths: allow_paths, disallow_paths: disallow_paths }
      externals = @crawler.crawl_site(url.dup, paths) do |doc|
        crawled << doc.url
        next unless doc

        # Start a thread for each page, checking for broken links.
        pool.process { find_broken_links(doc) }
      end

      # Wait for all threads to finish, even if url was invalid.
      pool.shutdown

      # Ensure the given website url is valid.
      raise "Invalid or broken URL: #{url}" unless externals

      retry_broken_links

      @manager.sort
      @manager.tally(url: url, pages_crawled: crawled.to_a, start: start)

      broken_links.any?
    ensure
      pool.shutdown if defined?(pool)
    end

    # Outputs the link report into a stream e.g. STDOUT or a file,
    # anything that respond_to? :puts. Defaults to STDOUT.
    def report(stream = STDOUT, type: :text,
               broken_verbose: true, ignored_verbose: false)
      klass = case type
              when :text
                BrokenLinkFinder::TextReporter
              when :html
                BrokenLinkFinder::HTMLReporter
              else
                raise "The type: must be :text or :html, not: :#{type}"
              end

      reporter = klass.new(stream, @sort,
                           broken_links, ignored_links,
                           @manager.broken_link_map, crawl_stats)
      reporter.call(broken_verbose: broken_verbose,
                    ignored_verbose: ignored_verbose)
    end

    private

    # Finds which links are unsupported or broken and records the details.
    def find_broken_links(page)
      record_unparsable_links(page) # Record them as broken.

      links = get_supported_links(page)

      # Iterate over the supported links checking if they're broken or not.
      links.each do |link|
        # Skip if the link has been encountered previously.
        next if @manager.all_intact_links.include?(link)

        if @manager.all_broken_links.include?(link)
          # The link has already been proven broken so simply record it.
          @manager.append_broken_link(page, link, map: false)
          next
        end

        # The link hasn't been encountered before so we crawl it.
        link_doc = crawl_link(page, link)

        # Determine if the crawled link is broken or not and record it.
        if link_broken?(link_doc)
          @manager.append_broken_link(page, link)
        else
          @manager.append_intact_link(link)
        end
      end

      nil
    end

    # Implements a retry mechanism for each of the broken links found.
    # Removes any broken links found to be working OK.
    def retry_broken_links
      sleep(SERVER_WAIT_TIME) # Give the servers a break, then retry the links.

      @manager.broken_link_map.select! do |link, href|
        # Don't retry unparsable links (which are Strings).
        next(true) unless href.is_a?(Wgit::Url)

        doc = @crawler.crawl(href.dup)

        if link_broken?(doc)
          true
        else
          @manager.remove_broken_link(link)
          false
        end
      end
    end

    # Record each unparsable link as a broken link.
    def record_unparsable_links(doc)
      doc.unparsable_links.each do |link|
        # We map the link ourselves because link is a String, not a Wgit::Url.
        @manager.append_broken_link(doc, link, map: false)
        @manager.broken_link_map[link] = link
      end
    end

    # Report and reject any non supported links. Any link that is absolute and
    # doesn't start with 'http' is unsupported e.g. 'mailto:blah' etc.
    def get_supported_links(doc)
      doc.all_links.reject do |link|
        if link.is_absolute? && !link.start_with?('http')
          @manager.append_ignored_link(doc.url, link)
          true
        end
      end
    end

    # Make the link absolute and crawl it, returning its Wgit::Document.
    def crawl_link(doc, link)
      link = link.prefix_base(doc)
      @crawler.crawl(link.dup) # We dup link to avoid recording any redirects.
    end

    # Return if the crawled link is broken or not.
    def link_broken?(doc)
      doc.nil? || @crawler.last_response.not_found? || has_broken_anchor(doc)
    end

    # Returns true if the link is/contains a broken anchor/fragment.
    # E.g. /about#top should contain a HTML element with an @id of 'top' etc.
    def has_broken_anchor(doc)
      raise 'The link document is nil' unless doc

      fragment = doc.url.fragment
      return false if fragment.nil? || fragment.empty?

      doc.xpath("//*[@id='#{fragment}']").empty?
    end

    alias crawl_page crawl_url
    alias crawl_r    crawl_site
  end
end
