module BrokenLinkFinder
  class Reporter
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
    def pretty_print_link_report(
      broken_verbose: true,
      ignored_verbose: false
    )
      report_broken_links(verbose: broken_verbose)
      report_ignored_links(verbose: ignored_verbose)
    end

    private

    # Report a summary of the broken links.
    def report_broken_links(verbose: true)
      if @broken_links.empty?
        println "Good news, there are no broken links!"
      else
        println "Below is a report of the different broken links found..."

        @broken_links.each do |key, values|
          msg = sort_by_page? ?
            "The following broken links were found on '#{key}':" :
            "The broken link '#{key}' was found on the following pages:"

          print msg
          values.each { |value| print value }
          print
        end
      end
    end

    # Report a summary of the ignored links.
    def report_ignored_links(verbose: false)
      if @ignored_links.any?
        println "Below are the non supported links found, you should check \
these manually:"

        @ignored_links.each do |key, values|
          msg = sort_by_page? ?
            "The following links were ignored on '#{key}':" :
            "The link '#{key}' was ignored on the following pages:"

          print msg
          values.each { |value| print value }
          print
        end
      end
    end

    # Return true if the sort is by page.
    def sort_by_page?
      @sort == :page
    end

    # Prints the text. Defaults to an blank line.
    def print(text = '')
      @stream.puts(text)
    end

    # Print the text and a blank line.
    def println(text)
      @stream.puts(text)
      @stream.puts
    end
  end
end
