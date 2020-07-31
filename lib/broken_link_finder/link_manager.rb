# frozen_string_literal: true

module BrokenLinkFinder
  # Class responsible for handling the link collection logic.
  class LinkManager
    # Used for mapping pages to broken links.
    attr_reader :broken_links

    # Used for mapping pages to ignored links.
    attr_reader :ignored_links

    # Used to record crawl statistics e.g. duration etc.
    attr_reader :crawl_stats

    # Used to map a link (as is) to its absolute (crawlable) form.
    attr_reader :broken_link_map

    # Used to prevent crawling a broken link twice.
    attr_reader :all_broken_links

    # Used to prevent crawling an intact link twice.
    attr_reader :all_intact_links

    # Used for building crawl statistics.
    attr_reader :all_ignored_links

    # Returns a new LinkManager instance with empty link collections.
    def initialize(sort)
      raise "Sort by either :page or :link, not #{sort}" \
      unless %i[page link].include?(sort)

      @sort = sort
      @lock = Mutex.new

      empty # Initialises the link collections.
    end

    # Initialise/empty the link collection objects.
    def empty
      @broken_links      = {}
      @ignored_links     = {}
      @crawl_stats       = {}
      @broken_link_map   = {}
      @all_broken_links  = Set.new
      @all_intact_links  = Set.new
      @all_ignored_links = Set.new
    end

    # Append key => [value] to the broken link collections.
    # If map: true, then the link will also be recorded in @broken_link_map.
    def append_broken_link(doc, link, map: true)
      key, value = get_key_value(doc.url, link)

      @lock.synchronize do
        @broken_links[key] = [] unless @broken_links[key]
        @broken_links[key] << value

        @all_broken_links << link

        @broken_link_map[link] = link.make_absolute(doc) if map
      end
    end

    # Remove the broken link from the necessary collections.
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

    # Append key => [value] to the ignored link collections.
    def append_ignored_link(url, link)
      key, value = get_key_value(url, link)

      @lock.synchronize do
        @ignored_links[key] = [] unless @ignored_links[key]
        @ignored_links[key] << value

        @all_ignored_links << link
      end
    end

    # Append link to @all_intact_links.
    def append_intact_link(link)
      @lock.synchronize { @all_intact_links << link }
    end

    # Sorts the link collection's keys and values alphabetically.
    def sort
      @broken_links.values.map(&:uniq!)
      @ignored_links.values.map(&:uniq!)

      @broken_links  = @broken_links.sort_by  { |k, _v| k }.to_h
      @ignored_links = @ignored_links.sort_by { |k, _v| k }.to_h

      @broken_links.each  { |_k, v| v.sort! }
      @ignored_links.each { |_k, v| v.sort! }
    end

    # Tally's up various statistics about the crawl and its links.
    def tally(url:, pages_crawled:, start:)
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

    private

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
  end
end
