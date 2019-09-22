# frozen_string_literal: true

# We extract all the Document's links, not just the links to other webpages.
Wgit::Document.define_extension(
  :all_links,
  '//*/@href | //*/@src', # Any element with a href or src attribute.
  singleton: false,
  text_content_only: true
) do |links|
  links&.map(&:to_url)&.uniq
end
