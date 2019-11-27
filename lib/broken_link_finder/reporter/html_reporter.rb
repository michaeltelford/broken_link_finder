# frozen_string_literal: true

module BrokenLinkFinder
  class HTMLReporter < Reporter
    # Creates a new HTMLReporter instance.
    # stream is any Object that responds to :puts and :print.
    def initialize(stream, sort, broken_links, ignored_links, broken_link_map)
      super
    end

    # Pretty print a report detailing the full link summary.
    def call(broken_verbose: true, ignored_verbose: false)
      puts '<div class="broken_link_finder_report">'

      report_broken_links(verbose: broken_verbose)
      report_ignored_links(verbose: ignored_verbose)

      puts '</div>'

      nil
    end

    private

    # Report a summary of the broken links.
    def report_broken_links(verbose: true)
      puts '<div class="broken_links">'

      if @broken_links.empty?
        puts_summary 'Good news, there are no broken links!', type: :broken
      else
        num_pages, num_links = get_hash_stats(@broken_links)
        puts_summary "Found #{num_links} broken link(s) across #{num_pages} page(s):", type: :broken

        @broken_links.each do |key, values|
          puts_group(key, type: :broken) # Puts the opening <p> element.

          if verbose || (values.length <= NUM_VALUES)
            values.each { |value| puts_group_item value, type: :broken }
          else # Only print N values and summarise the rest.
            NUM_VALUES.times { |i| puts_group_item values[i], type: :broken }

            objects = sort_by_page? ? 'link(s)' : 'page(s)'
            puts "+ #{values.length - NUM_VALUES} other #{objects}, remove --concise to see them all<br />"
          end

          puts '</p>'
        end
      end

      puts '</div>'
    end

    # Report a summary of the ignored links.
    def report_ignored_links(verbose: false)
      puts '<div class="ignored_links">'

      if @ignored_links.any?
        num_pages, num_links = get_hash_stats(@ignored_links)
        puts_summary "Ignored #{num_links} unsupported link(s) across #{num_pages} page(s), which you should check manually:", type: :ignored

        @ignored_links.each do |key, values|
          puts_group(key, type: :ignored) # Puts the opening <p> element.

          if verbose || (values.length <= NUM_VALUES)
            values.each { |value| puts_group_item value, type: :ignored }
          else # Only print N values and summarise the rest.
            NUM_VALUES.times { |i| puts_group_item values[i], type: :ignored }

            objects = sort_by_page? ? 'link(s)' : 'page(s)'
            puts "+ #{values.length - NUM_VALUES} other #{objects}, use --verbose to see them all<br />"
          end

          puts '</p>'
        end
      end

      puts '</div>'
    end

    def puts_summary(text, type:)
      klass = (type == :broken) ? 'broken_links_summary' : 'ignored_links_summary'
      puts "<p class=\"#{klass}\">#{text}</p>"
    end

    def puts_group(link, type:)
      href = build_url(link)
      a_element = "<a href=\"#{href}\">#{link}</a>"

      case type
      when :broken
        msg = sort_by_page? ?
          "The following broken links were found on '#{a_element}':" :
          "The broken link '#{a_element}' was found on the following pages:"
        klass = 'broken_links_group'
      when :ignored
        msg = sort_by_page? ?
          "The following links were ignored on '#{a_element}':" :
          "The link '#{a_element}' was ignored on the following pages:"
        klass = 'ignored_links_group'
      else
        raise "type: must be :broken or :ignored, not: #{type}"
      end

      puts "<p class=\"#{klass}\">"
      puts msg + '<br />'
    end

    def puts_group_item(value, type:)
      klass = (type == :broken) ? 'broken_links_group_item' : 'ignored_links_group_item'
      puts "<a class=\"#{klass}\" href=\"#{build_url(value)}\">#{value}</a><br />"
    end

    def build_url(link)
      return link if link.to_url.absolute?
      @broken_link_map.fetch(link)
    end

    alias_method :report, :call
  end
end
