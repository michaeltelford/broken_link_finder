# frozen_string_literal: true

# Define a method on each doc for recording unparsable links.
# Unparsable links are recorded as broken links by Finder.
class Wgit::Document
  def unparsable_links
    @unparsable_links ||= []
  end
end

# Returns a Wgit::Url or nil (if link is unparsable).
# A proc is preferrable to a function to avoid polluting the global namespace.
parse_link = lambda do |doc, link|
  Wgit::Url.new(link)
rescue StandardError
  doc.unparsable_links << link
  nil
end

# We extract all the Document's links e.g. <a>, <img>, <script>, <link> etc.
Wgit::Document.define_extractor(
  :all_links,
  '//*/@href | //*/@src', # Any element's href or src attribute URL.
  singleton: false,
  text_content_only: true
) do |links, doc|
  links
    .uniq
    .map { |link| parse_link.call(doc, link) }
    .compact
end
