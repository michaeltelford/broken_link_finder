# frozen_string_literal: true

# We extract all the Document's links, not just the links to other webpages.
Wgit::Document.define_extension(
  :all_links,
  '//*/@href | //*/@src', # Any element's href or src attribute URL.
  singleton: false,
  text_content_only: true
) do |links|
  links
    .uniq
    .map { |link| Wgit::Url.parse_or_nil(link) }
    .compact # Remove any invalid URLs.
end
