module BrokenLinkFinder
  class Reporter
    # The amount of pages/links to display when verbose is false.
    NUM_SNIPPETS = 3.freeze

    # Creates a new Reporter instance.
    # stream is any Object that responds to :puts.
    def initialize(stream, sort, broken_links, ignored_links)
      @stream = stream
      @sort = sort
      @broken_links = broken_links
      @ignored_links = ignored_links

      raise "stream must respond_to? :puts" unless @stream.respond_to?(:puts)
      unless [:page, :link].include?(sort)
        raise "sort by either :page or :link, not #{@sort}"
      end
    end

    # Pretty print a report detailing the link summary.
    def pretty_print_link_report(broken_verbose: true, ignored_verbose: false)
      report_broken_links(verbose: broken_verbose)
      report_ignored_links(verbose: ignored_verbose)
    end

    private

    # Report a summary of the broken links.
    def report_broken_links(verbose: true)
      if @broken_links.empty?
        println "Good news, there are no broken links!"
      else
        num_pages, num_links = get_hash_stats(@broken_links)
        println "Found #{num_links} broken link(s) across #{num_pages} page(s)"

        @broken_links.each do |key, values|
          msg = sort_by_page? ?
            "The following broken links were found on '#{key}':" :
            "The broken link '#{key}' was found on the following pages:"
          print msg

          if verbose or values.length <= NUM_SNIPPETS
            values.each { |value| print value }
          else # Only print N values.
            NUM_SNIPPETS.times do |i|
              print values[i]
            end

            objects = sort_by_page? ? 'link(s)' : 'page(s)'
            print "+ #{values.length - NUM_SNIPPETS} other #{objects}, remove --concise to see them all"
          end
          print
        end
      end
    end

    # Report a summary of the ignored links.
    def report_ignored_links(verbose: false)
      if @ignored_links.any?
        println "Below are the non supported links found, you should check \
these manually:"

        @ignored_links.each_with_index do |pair, i|
          key, values = *pair
          break if !verbose and i >= 1 # Print only the first key/value pair.

          msg = sort_by_page? ?
            "The following links were ignored on '#{key}':" :
            "The link '#{key}' was ignored on the following pages:"
          print msg

          if verbose or values.length <= NUM_SNIPPETS
            values.each { |value| print value }
          else # Only print N values.
            NUM_SNIPPETS.times do |i|
              print values[i]
            end

            objects = sort_by_page? ? 'link(s)' : 'page(s)'
            print "+ #{values.length - NUM_SNIPPETS} other #{objects}, use --verbose to see them all"
          end
          print
        end

        # Summarise the total ignored links found.
        if !verbose and @ignored_links.length > 1
          num_pages, num_links = get_hash_stats(@ignored_links)
          println "In total, #{num_links} links have been ignored across #{num_pages} pages, use --verbose to see them all"
        end
      end
    end

    # Return true if the sort is by page.
    def sort_by_page?
      @sort == :page
    end

    # Prints the text + \n. Defaults to an blank line.
    def print(text = '')
      @stream.puts(text)
    end

    # Prints the text + \n and a blank line.
    def println(text)
      @stream.puts(text)
      @stream.puts
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
  end
end
