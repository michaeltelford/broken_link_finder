# frozen_string_literal: true

# Define a method on each doc for recording unparsable links.
class Wgit::Document
  def unparsable_links
    @unparsable_links ||= []
  end
end

# We extract all the Document's links e.g. <a>, <img> etc.
Wgit::Document.define_extension(
  :all_links,
  '//*/@href | //*/@src', # Any element's href or src attribute URL.
  singleton: false,
  text_content_only: true
) do |links, doc|
  links
    .uniq
    .map do |link|
      Wgit::Url.new(link)
    rescue StandardError
      doc.unparsable_links << link
      nil
    end
    .compact
end
