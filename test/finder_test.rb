require 'helpers/test_helper'

class FinderTest < TestHelper
  def test_initialize_from_module
    finder = BrokenLinkFinder.new sort: :link, max_threads: 10

    assert_equal 10, finder.max_threads
    assert_equal :link, finder.sort
    refute_nil finder.instance_variable_get(:@crawler)
    refute_nil manager(finder)
    assert_empty finder.broken_links
    assert_empty finder.ignored_links
    assert_empty finder.crawl_stats
  end

  def test_initialize
    finder = Finder.new

    assert_equal 100, finder.max_threads
    assert_equal :page, finder.sort
    refute_nil finder.instance_variable_get(:@crawler)
    refute_nil manager(finder)
    assert_empty finder.broken_links
    assert_empty finder.ignored_links
    assert_empty finder.crawl_stats

    finder = Finder.new sort: :link, max_threads: 10

    assert_equal :link, finder.sort
    assert_equal 10, finder.max_threads

    assert_raises(StandardError) { LinkManager.new :blah }
  end

  def test_crawl_url
    finder = Finder.new
    assert finder.crawl_url 'http://mock-server.com/'

    assert_equal({
                   'http://mock-server.com/' => [
                     'https://doesnt-exist.com',
                     'not_found'
                   ]
                 }, finder.broken_links)
    assert_equal({
                   'http://mock-server.com/' => [
                     'mailto:youraddress@yourmailserver.com',
                     'tel:+13174562564'
                   ]
                 }, finder.ignored_links)

    assert_equal 'http://mock-server.com/', finder.crawl_stats[:url]
    assert_equal ['http://mock-server.com/'], finder.crawl_stats[:pages_crawled]
    assert_equal 1, finder.crawl_stats[:num_pages]
    assert_equal 9, finder.crawl_stats[:num_links]
    assert_equal 2, finder.crawl_stats[:num_broken_links]
    assert_equal 5, finder.crawl_stats[:num_intact_links]
    assert_equal 2, finder.crawl_stats[:num_ignored_links]
    assert finder.crawl_stats[:duration] > 0.0
  end

  def test_crawl_url__sort_by_link
    finder = Finder.new sort: :link
    assert finder.crawl_url 'http://mock-server.com/'

    assert_equal({
                   'https://doesnt-exist.com' => [
                     'http://mock-server.com/'
                   ],
                   'not_found' => [
                     'http://mock-server.com/'
                   ]
                 }, finder.broken_links)
    assert_equal({
                   'mailto:youraddress@yourmailserver.com' => [
                     'http://mock-server.com/'
                   ],
                   'tel:+13174562564' => [
                     'http://mock-server.com/'
                   ]
                 }, finder.ignored_links)

    assert_equal 'http://mock-server.com/', finder.crawl_stats[:url]
    assert_equal ['http://mock-server.com/'], finder.crawl_stats[:pages_crawled]
    assert_equal 1, finder.crawl_stats[:num_pages]
    assert_equal 9, finder.crawl_stats[:num_links]
    assert_equal 2, finder.crawl_stats[:num_broken_links]
    assert_equal 5, finder.crawl_stats[:num_intact_links]
    assert_equal 2, finder.crawl_stats[:num_ignored_links]
    assert finder.crawl_stats[:duration] > 0.0
  end

  def test_crawl_url__no_broken_links
    finder = Finder.new
    refute finder.crawl_url('http://mock-server.com/location')

    assert_empty finder.broken_links
    assert_empty finder.ignored_links
    assert_equal 'http://mock-server.com/location', finder.crawl_stats[:url]
    assert_equal ['http://mock-server.com/location'], finder.crawl_stats[:pages_crawled]
    assert_equal 1, finder.crawl_stats[:num_pages]
    assert_equal 2, finder.crawl_stats[:num_links]
    assert_equal 0, finder.crawl_stats[:num_broken_links]
    assert_equal 2, finder.crawl_stats[:num_intact_links]
    assert_equal 0, finder.crawl_stats[:num_ignored_links]
    assert finder.crawl_stats[:duration] > 0.0
  end

  def test_crawl_url__no_broken_links__sort_by_link
    finder = Finder.new sort: :link
    refute finder.crawl_url('http://mock-server.com/location')

    assert_empty finder.broken_links
    assert_empty finder.ignored_links
    assert_equal 'http://mock-server.com/location', finder.crawl_stats[:url]
    assert_equal ['http://mock-server.com/location'], finder.crawl_stats[:pages_crawled]
    assert_equal 1, finder.crawl_stats[:num_pages]
    assert_equal 2, finder.crawl_stats[:num_links]
    assert_equal 0, finder.crawl_stats[:num_broken_links]
    assert_equal 2, finder.crawl_stats[:num_intact_links]
    assert_equal 0, finder.crawl_stats[:num_ignored_links]
    assert finder.crawl_stats[:duration] > 0.0
  end

  def test_crawl_url__links_page
    finder = Finder.new
    assert finder.crawl_url 'https://example.co.uk/links.html'
    expected = {
      'https://example.co.uk/links.html' => [
        '/images/non-existent_logo.png',
        '/links.html#anchorthatdoesnotexist',
        '/nonexistent_page.html',
        '/nonexistent_page.html#anchorthatdoesnotexist',

        'https://example.co.uk/images/non-existing_logo.png',
        'https://example.co.uk/links.html#anchorthatdoesnotexist',
        'https://example.co.uk/nonexisting_page.html',
        'https://example.co.uk/nonexisting_page.html#anchorthatdoesnotexist',

        'https://example.com#anchorthandoesnotexist',
        'https://example.com/brokenlink',
        'https://example.com/brokenlink#anchorthandoesnotexist',
        'https://example.com/images/non-existing_logo.png',

        'https://thisdomaindoesnotexist-thouthou.com/badpage.html',
        'https://thisdomaindoesnotexist-thouthou.com/badpage.html#anchorthatdoesnotexist',
        'https://thisdomaindoesnotexist-thouthou.com/nonexistentimage.png'
      ]
    }

    assert_equal expected, finder.broken_links
    assert_empty finder.ignored_links
    assert_equal 'https://example.co.uk/links.html', finder.crawl_stats[:url]
    assert_equal ['https://example.co.uk/links.html'], finder.crawl_stats[:pages_crawled]
    assert_equal 1, finder.crawl_stats[:num_pages]
    assert_equal 15, finder.crawl_stats[:num_links]
    assert_equal 15, finder.crawl_stats[:num_broken_links]
    assert_equal 0, finder.crawl_stats[:num_intact_links]
    assert_equal 0, finder.crawl_stats[:num_ignored_links]
    assert finder.crawl_stats[:duration] > 0.0
  end

  def test_crawl_url__links_page__sort_by_link
    finder = Finder.new sort: :link
    assert finder.crawl_url 'https://example.co.uk/links.html'
    expected = {
      '/images/non-existent_logo.png' => ['https://example.co.uk/links.html'],
      '/nonexistent_page.html' => ['https://example.co.uk/links.html'],
      '/nonexistent_page.html#anchorthatdoesnotexist' => ['https://example.co.uk/links.html'],
      '/links.html#anchorthatdoesnotexist' => ['https://example.co.uk/links.html'],

      'https://example.com/images/non-existing_logo.png' => ['https://example.co.uk/links.html'],
      'https://example.com/brokenlink' => ['https://example.co.uk/links.html'],
      'https://example.com/brokenlink#anchorthandoesnotexist' => ['https://example.co.uk/links.html'],
      'https://example.com#anchorthandoesnotexist' => ['https://example.co.uk/links.html'],

      'https://example.co.uk/images/non-existing_logo.png' => ['https://example.co.uk/links.html'],
      'https://example.co.uk/nonexisting_page.html' => ['https://example.co.uk/links.html'],
      'https://example.co.uk/nonexisting_page.html#anchorthatdoesnotexist' => ['https://example.co.uk/links.html'],
      'https://example.co.uk/links.html#anchorthatdoesnotexist' => ['https://example.co.uk/links.html'],

      'https://thisdomaindoesnotexist-thouthou.com/badpage.html' => ['https://example.co.uk/links.html'],
      'https://thisdomaindoesnotexist-thouthou.com/nonexistentimage.png' => ['https://example.co.uk/links.html'],
      'https://thisdomaindoesnotexist-thouthou.com/badpage.html#anchorthatdoesnotexist' => ['https://example.co.uk/links.html']
    }
    assert_equal expected, finder.broken_links
    assert_empty finder.ignored_links

    assert_equal 'https://example.co.uk/links.html', finder.crawl_stats[:url]
    assert_equal ['https://example.co.uk/links.html'], finder.crawl_stats[:pages_crawled]
    assert_equal 1, finder.crawl_stats[:num_pages]
    assert_equal 15, finder.crawl_stats[:num_links]
    assert_equal 15, finder.crawl_stats[:num_broken_links]
    assert_equal 0, finder.crawl_stats[:num_intact_links]
    assert_equal 0, finder.crawl_stats[:num_ignored_links]
    assert finder.crawl_stats[:duration] > 0.0
  end

  def test_crawl_url__invalid
    finder = Finder.new
    finder.crawl_url 'https://server-error.com'

    flunk
  rescue RuntimeError => e
    assert_equal 'Invalid or broken URL: https://server-error.com', e.message
    assert_empty finder.broken_links
    assert_empty finder.ignored_links
    assert_empty finder.crawl_stats
  end

  def test_crawl_site
    finder = Finder.new
    assert finder.crawl_site 'http://mock-server.com/'

    assert_equal({
                   'http://mock-server.com/' => [
                     'https://doesnt-exist.com',
                     'not_found'
                   ],
                   'http://mock-server.com/about' => [
                     'https://doesnt-exist.com'
                   ],
                   'http://mock-server.com/about?q=world' => [
                     'https://doesnt-exist.com'
                   ],
                   'http://mock-server.com/contact' => [
                     '#doesntexist',
                     'https://doesnt-exist.com',
                     'not_found'
                   ]
                 }, finder.broken_links)
    assert_equal({
                   'http://mock-server.com/' => [
                     'mailto:youraddress@yourmailserver.com',
                     'tel:+13174562564'
                   ],
                   'http://mock-server.com/contact' => [
                     'ftp://websiteaddress.com'
                   ]
                 }, finder.ignored_links)

    assert_equal 'http://mock-server.com/', finder.crawl_stats[:url]
    assert_equal([
      'http://mock-server.com/',
      'http://mock-server.com/contact',
      'http://mock-server.com/location',
      'http://mock-server.com/about',
      'http://mock-server.com/not_found',
      'http://mock-server.com/location?q=hello',
      'http://mock-server.com/about?q=world'
    ], finder.crawl_stats[:pages_crawled])
    assert_equal 7, finder.crawl_stats[:num_pages]
    assert_equal 20, finder.crawl_stats[:num_links]
    assert_equal 3, finder.crawl_stats[:num_broken_links]
    assert_equal 14, finder.crawl_stats[:num_intact_links]
    assert_equal 3, finder.crawl_stats[:num_ignored_links]
    assert finder.crawl_stats[:duration] > 0.0

    # Check it can be run multiple times consecutively without error.
    assert finder.crawl_site 'http://mock-server.com/'
  end

  def test_crawl_site__paths
    finder = Finder.new
    paths = { allow_paths: 'about*', disallow_paths: 'blog*' }
    assert finder.crawl_site 'http://mock-server.com/', **paths

    assert_equal({
                   'http://mock-server.com/' => [
                     'https://doesnt-exist.com',
                     'not_found'
                   ],
                   'http://mock-server.com/about' => [
                     'https://doesnt-exist.com'
                   ],
                   'http://mock-server.com/about?q=world' => [
                     'https://doesnt-exist.com'
                   ]
                 }, finder.broken_links)
    assert_equal({
                   'http://mock-server.com/' => [
                     'mailto:youraddress@yourmailserver.com',
                     'tel:+13174562564'
                   ]
                 }, finder.ignored_links)

    assert_equal 'http://mock-server.com/', finder.crawl_stats[:url]
    assert_equal([
      'http://mock-server.com/',
      'http://mock-server.com/about',
      'http://mock-server.com/about?q=world'
    ], finder.crawl_stats[:pages_crawled])
    assert_equal 3, finder.crawl_stats[:num_pages]
    assert_equal 14, finder.crawl_stats[:num_links]
    assert_equal 2, finder.crawl_stats[:num_broken_links]
    assert_equal 10, finder.crawl_stats[:num_intact_links]
    assert_equal 2, finder.crawl_stats[:num_ignored_links]
    assert finder.crawl_stats[:duration] > 0.0
  end

  def test_crawl_site__sort_by_link
    finder = Finder.new sort: :link
    assert finder.crawl_site 'http://mock-server.com/'

    assert_equal({
                   '#doesntexist' => [
                     'http://mock-server.com/contact'
                   ],
                   'https://doesnt-exist.com' => [
                     'http://mock-server.com/',
                     'http://mock-server.com/about',
                     'http://mock-server.com/about?q=world',
                     'http://mock-server.com/contact'
                   ],
                   'not_found' => [
                     'http://mock-server.com/',
                     'http://mock-server.com/contact'
                   ]
                 }, finder.broken_links)
    assert_equal({
                   'ftp://websiteaddress.com' => ['http://mock-server.com/contact'],
                   'mailto:youraddress@yourmailserver.com' => ['http://mock-server.com/'],
                   'tel:+13174562564' => ['http://mock-server.com/']
                 }, finder.ignored_links)

    assert_equal 'http://mock-server.com/', finder.crawl_stats[:url]
    assert_equal([
      'http://mock-server.com/',
      'http://mock-server.com/contact',
      'http://mock-server.com/location',
      'http://mock-server.com/about',
      'http://mock-server.com/not_found',
      'http://mock-server.com/location?q=hello',
      'http://mock-server.com/about?q=world'
    ], finder.crawl_stats[:pages_crawled])
    assert_equal 7, finder.crawl_stats[:num_pages]
    assert_equal 20, finder.crawl_stats[:num_links]
    assert_equal 3, finder.crawl_stats[:num_broken_links]
    assert_equal 14, finder.crawl_stats[:num_intact_links]
    assert_equal 3, finder.crawl_stats[:num_ignored_links]
    assert finder.crawl_stats[:duration] > 0.0

    # Check it can be run multiple times consecutively without error.
    assert finder.crawl_site 'http://mock-server.com/'
  end

  def test_crawl_site__invalid
    finder = Finder.new
    finder.crawl_site 'https://server-error.com'

    flunk
  rescue RuntimeError => e
    assert_equal 'Invalid or broken URL: https://server-error.com', e.message
    assert_empty finder.broken_links
    assert_empty finder.ignored_links
    assert_empty finder.crawl_stats
  end

  def test_retry_mechanism
    finder = Finder.new
    refute finder.crawl_url('http://www.retry.com')

    assert_empty finder.broken_links
    assert_empty finder.ignored_links
    assert_equal 'http://www.retry.com', finder.crawl_stats[:url]
    assert_equal ['http://www.retry.com'], finder.crawl_stats[:pages_crawled]
    assert_equal 1, finder.crawl_stats[:num_pages]
    assert_equal 1, finder.crawl_stats[:num_links]
    assert_equal 0, finder.crawl_stats[:num_broken_links]
    assert_equal 1, finder.crawl_stats[:num_intact_links]
    assert_equal 0, finder.crawl_stats[:num_ignored_links]
    assert finder.crawl_stats[:duration] > 0.0
    assert_empty manager(finder).broken_link_map
  end

  def test_retry_mechanism__sort_by_link
    finder = Finder.new sort: :link
    refute finder.crawl_url('http://www.retry.com')

    assert_empty finder.broken_links
    assert_empty finder.ignored_links
    assert_equal 'http://www.retry.com', finder.crawl_stats[:url]
    assert_equal ['http://www.retry.com'], finder.crawl_stats[:pages_crawled]
    assert_equal 1, finder.crawl_stats[:num_pages]
    assert_equal 1, finder.crawl_stats[:num_links]
    assert_equal 0, finder.crawl_stats[:num_broken_links]
    assert_equal 1, finder.crawl_stats[:num_intact_links]
    assert_equal 0, finder.crawl_stats[:num_ignored_links]
    assert finder.crawl_stats[:duration] > 0.0
    assert_empty manager(finder).broken_link_map
  end

  def test_broken_links__on_redirect
    # http://broken.external.redirect.test.com (contains <a> link to:)
    #  |> http://broken.external.redirect.com (301 redirects to:)
    #      |> https://server-error.com (500 internal server error)

    finder = Finder.new
    assert finder.crawl_url('http://broken.external.redirect.test.com')

    # We assert the redirected to URL isn't recorded.
    assert_equal({
      'http://broken.external.redirect.test.com' => ['http://broken.external.redirect.com']
    }, finder.broken_links)
    assert_equal({
      'http://broken.external.redirect.com' => 'http://broken.external.redirect.com'
    }, manager(finder).broken_link_map)
    assert(
      manager(finder).all_broken_links
            .include?('http://broken.external.redirect.com')
    )
    refute(
      manager(finder).all_broken_links
            .include?('https://server-error.com')
    )
  end

  def test_crawl_stats__on_redirect
    # http://mock-server.com/redirect/2 (301 redirects to:)
    #  |> /location (contains no broken links)

    finder = Finder.new
    refute finder.crawl_url('http://mock-server.com/redirect/2')

    # We assert the redirected to URL isn't recorded.
    assert_equal 'http://mock-server.com/redirect/2', finder.crawl_stats[:url]
  end

  def test_anchor__on_redirect
    # http://redirect.anchor.com (contains <a> link to:)
    #  |> http://redirect.com#top (301 redirect to:)
    #      |> http://no.anchor.com (Missing #top anchor on redirected-to page)

    finder = Finder.new

    # Assert http://no.anchor.com#top isn't a broken link.
    refute finder.crawl_url('http://redirect.anchor.com')
  end

  def test_unparsable_links
    finder = Finder.new

    assert finder.crawl_url('http://unparsable.com')
    assert_equal({
      'http://unparsable.com' => [
        'http://',
        'https://',
        'https://server-error.com' # Parsable but broken link.
      ]
    }, finder.broken_links)
    assert_empty finder.ignored_links
    assert [
      'http://', 'https://', 'https://server-error.com'
    ], manager(finder).all_broken_links
    assert_equal({
      'http://'  => 'http://',
      'https://' => 'https://',
      'https://server-error.com' => 'https://server-error.com'
    }, manager(finder).broken_link_map)

    assert_equal 'http://unparsable.com', finder.crawl_stats[:url]
    assert_equal ['http://unparsable.com'], finder.crawl_stats[:pages_crawled]
    assert_equal 1, finder.crawl_stats[:num_pages]
    assert_equal 4, finder.crawl_stats[:num_links]
    assert_equal 3, finder.crawl_stats[:num_broken_links]
    assert_equal 1, finder.crawl_stats[:num_intact_links]
    assert_equal 0, finder.crawl_stats[:num_ignored_links]
    assert finder.crawl_stats[:duration] > 0.0
  end

  private

  def manager(finder)
    finder.instance_variable_get(:@manager)
  end
end
