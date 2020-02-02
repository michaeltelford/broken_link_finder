# frozen_string_literal: true

module BrokenLinkFinder
  # Generic reporter class to be inherited from by format specific reporters.
  class Reporter
    # The amount of pages/links to display when verbose is false.
    NUM_VALUES = 3

    # Returns a new Reporter instance.
    # stream is any Object that responds to :puts and :print.
    def initialize(stream, sort,
                   broken_links, ignored_links,
                   broken_link_map, crawl_stats)
      unless stream.respond_to?(:puts) && stream.respond_to?(:print)
        raise 'stream must respond_to? :puts and :print'
      end
      raise "sort by either :page or :link, not #{sort}" \
      unless %i[page link].include?(sort)

      @stream          = stream
      @sort            = sort
      @broken_links    = broken_links
      @ignored_links   = ignored_links
      @broken_link_map = broken_link_map
      @crawl_stats     = crawl_stats
    end

    # Pretty print a report detailing the full link summary.
    def call(broken_verbose: true, ignored_verbose: false)
      raise 'Not implemented by parent class'
    end

    protected

    # Return true if the sort is by page.
    def sort_by_page?
      @sort == :page
    end

    # Returns the key/value statistics of hash e.g. the number of keys and
    # combined values. The hash should be of the format: { 'str' => [...] }.
    # Use like: `num_pages, num_links = get_hash_stats(links)`.
    def get_hash_stats(hash)
      num_keys   = hash.keys.length
      num_values = hash.values.flatten.uniq.length

      sort_by_page? ?
        [num_keys, num_values] :
        [num_values, num_keys]
    end

    # Prints the text. Defaults to a blank line.
    def print(text = '')
      @stream.print(text)
    end

    # Prints the text + \n. Defaults to a blank line.
    def puts(text = '')
      @stream.puts(text)
    end

    # Prints text + \n\n.
    def putsn(text)
      puts(text)
      puts
    end

    # Prints \n + text + \n.
    def nputs(text)
      puts
      puts(text)
    end

    alias_method :report, :call
  end
end
