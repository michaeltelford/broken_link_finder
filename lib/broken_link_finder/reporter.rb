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
        @stream.puts("Good news, there are no broken links!")
        @stream.puts("")
      else
        @stream.puts("Below is a report of the different broken links found...")
        @stream.puts("")

        @broken_links.each do |page, links|
          @stream.puts("The following broken links exist on #{page}:")
          links.each do |link|
            @stream.puts(link)
          end
          @stream.puts("")
        end
      end
    end

    # Report a summary of the ignored links.
    def report_ignored_links(verbose: false)
      if @ignored_links.any?
        @stream.puts("Below is a breakdown of the non supported links found, \
you should check these manually:")
        @stream.puts("")

        @ignored_links.each do |page, links|
          @stream.puts("The following links were ignored on #{page}:")
          links.each do |link|
            @stream.puts(link)
          end
          @stream.puts("")
        end
      end
    end
  end
end
