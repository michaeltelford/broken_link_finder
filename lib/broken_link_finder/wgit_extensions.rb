require 'wgit'

# We pull out all of a Document's links, not just the links to other webpages.
Wgit::Document.define_extension(
  :all_links,
  '//*/@href | //*/@src',
  singleton: false,
  text_content_only: true,
) do |links|
  if links
    links = links.
      map do |link|
        Wgit::Url.new(link)
      rescue
        nil
      end.
      compact.
      uniq
  end
  links
end
