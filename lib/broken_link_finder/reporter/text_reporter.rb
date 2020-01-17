# frozen_string_literal: true

module BrokenLinkFinder
  class TextReporter < Reporter
    # Creates a new TextReporter instance.
    # stream is any Object that responds to :puts and :print.
    def initialize(stream, sort,
                   broken_links, ignored_links,
                   broken_link_map, crawl_stats)
      super
    end

    # Pretty print a report detailing the full link summary.
    def call(broken_verbose: true, ignored_verbose: false)
      report_crawl_summary
      report_broken_links(verbose: broken_verbose)
      report_ignored_links(verbose: ignored_verbose)

      nil
    end

    private

    # Report a summary of the overall crawl.
    def report_crawl_summary
      putsn format(
        'Crawled %s (%s page(s) in %s seconds)',
        @crawl_stats[:url],
        @crawl_stats[:num_pages],
        @crawl_stats[:duration]&.truncate(2)
      )
    end

    # Report a summary of the broken links.
    def report_broken_links(verbose: true)
      if @broken_links.empty?
        puts 'Good news, there are no broken links!'
      else
        num_pages, num_links = get_hash_stats(@broken_links)
        puts "Found #{num_links} unique broken link(s) across #{num_pages} page(s):"

        @broken_links.each do |key, values|
          msg = sort_by_page? ?
            "The following broken links were found on '#{key}':" :
            "The broken link '#{key}' was found on the following pages:"
          nputs msg

          if verbose || (values.length <= NUM_VALUES)
            values.each { |value| puts value }
          else # Only print N values and summarise the rest.
            NUM_VALUES.times { |i| puts values[i] }

            objects = sort_by_page? ? 'link(s)' : 'page(s)'
            puts "+ #{values.length - NUM_VALUES} other #{objects}, remove --concise to see them all"
          end
        end
      end
    end

    # Report a summary of the ignored links.
    def report_ignored_links(verbose: false)
      if @ignored_links.any?
        num_pages, num_links = get_hash_stats(@ignored_links)
        nputs "Ignored #{num_links} unique unsupported link(s) across #{num_pages} page(s), which you should check manually:"

        @ignored_links.each do |key, values|
          msg = sort_by_page? ?
            "The following links were ignored on '#{key}':" :
            "The link '#{key}' was ignored on the following pages:"
          nputs msg

          if verbose || (values.length <= NUM_VALUES)
            values.each { |value| puts value }
          else # Only print N values and summarise the rest.
            NUM_VALUES.times { |i| puts values[i] }

            objects = sort_by_page? ? 'link(s)' : 'page(s)'
            puts "+ #{values.length - NUM_VALUES} other #{objects}, use --verbose to see them all"
          end
        end
      end
    end

    alias_method :report, :call
  end
end
