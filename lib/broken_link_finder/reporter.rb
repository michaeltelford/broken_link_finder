module BrokenLinkFinder
  class Reporter
    # The amount of pages/links to display when verbose is false.
    NUM_VALUES = 3.freeze

    # Creates a new Reporter instance.
    # stream is any Object that responds to :puts.
    def initialize(stream, sort, broken_links, ignored_links)
      raise "stream must respond_to? :puts" unless stream.respond_to?(:puts)
      unless [:page, :link].include?(sort)
        raise "sort by either :page or :link, not #{sort}"
      end

      @stream         = stream
      @sort           = sort
      @broken_links   = broken_links
      @ignored_links  = ignored_links
    end

    # Pretty print a report detailing the link summary.
    def pretty_print_link_report(broken_verbose: true, ignored_verbose: false)
      report_broken_links(verbose: broken_verbose)
      report_ignored_links(verbose: ignored_verbose)
      nil
    end

    private

    # Report a summary of the broken links.
    def report_broken_links(verbose: true)
      if @broken_links.empty?
        print "Good news, there are no broken links!"
      else
        num_pages, num_links = get_hash_stats(@broken_links)
        print "Found #{num_links} broken link(s) across #{num_pages} page(s):"

        @broken_links.each do |key, values|
          msg = sort_by_page? ?
            "The following broken links were found on '#{key}':" :
            "The broken link '#{key}' was found on the following pages:"
          nprint msg

          if verbose or values.length <= NUM_VALUES
            values.each { |value| print value }
          else # Only print N values and summarise the rest.
            NUM_VALUES.times { |i| print values[i] }

            objects = sort_by_page? ? 'link(s)' : 'page(s)'
            print "+ #{values.length - NUM_VALUES} other #{objects}, remove --concise to see them all"
          end
        end
      end
    end

    # Report a summary of the ignored links.
    def report_ignored_links(verbose: false)
      if @ignored_links.any?
        num_pages, num_links = get_hash_stats(@ignored_links)
        nprint "Ignored #{num_links} unsupported link(s) across #{num_pages} page(s), which you should check manually:"

        @ignored_links.each do |key, values|
          msg = sort_by_page? ?
            "The following links were ignored on '#{key}':" :
            "The link '#{key}' was ignored on the following pages:"
          nprint msg

          if verbose or values.length <= NUM_VALUES
            values.each { |value| print value }
          else # Only print N values and summarise the rest.
            NUM_VALUES.times { |i| print values[i] }

            objects = sort_by_page? ? 'link(s)' : 'page(s)'
            print "+ #{values.length - NUM_VALUES} other #{objects}, use --verbose to see them all"
          end
        end
      end
    end

    # Return true if the sort is by page.
    def sort_by_page?
      @sort == :page
    end

    # Returns the key/value statistics of hash e.g. the number of keys and
    # combined values. The hash should be of the format: { 'str' => [...] }.
    # Use like: `num_pages, num_links = get_hash_stats(links)`.
    def get_hash_stats(hash)
      num_keys = hash.keys.length
      values = hash.values.flatten
      num_values = sort_by_page? ? values.length : values.uniq.length

      sort_by_page? ?
        [num_keys, num_values] :
        [num_values, num_keys]
    end

    # Prints the text + \n. Defaults to a blank line.
    def print(text = '')
      @stream.puts(text)
    end

    # Prints text + \n\n.
    def printn(text)
      print(text)
      print
    end

    # Prints \n + text + \n.
    def nprint(text)
      print
      print(text)
    end
  end
end
