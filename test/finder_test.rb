require 'helpers/test_helper'

class FinderTest < TestHelper
  def test_initialize_from_module
    finder = BrokenLinkFinder.new

    assert_equal Hash.new, finder.broken_links
    assert_equal Hash.new, finder.ignored_links
    refute_nil finder.instance_variable_get(:@crawler)
  end

  def test_initialize
    finder = Finder.new

    assert_equal Hash.new, finder.broken_links
    assert_equal Hash.new, finder.ignored_links
    assert_equal :page, finder.instance_variable_get(:@sort)
    refute_nil finder.instance_variable_get(:@crawler)

    finder = Finder.new sort: :link
    assert_equal :link, finder.instance_variable_get(:@sort)
  end

  def test_clear_links
    finder = Finder.new
    finder.instance_variable_set :@broken_links, { name: 'foo' }
    finder.instance_variable_set :@ignored_links, { name: 'bar' }
    finder.clear_links

    assert finder.broken_links.empty?
    assert finder.ignored_links.empty?
  end

  def test_crawl_url
    finder = Finder.new
    assert finder.crawl_url 'http://mock-server.com/'

    assert_equal({
      'http://mock-server.com/' => [
        'https://doesnt-exist.com',
        'not_found',
      ],
    }, finder.broken_links)
    assert_equal({
      'http://mock-server.com/' => [
        'mailto:youraddress@yourmailserver.com',
        'tel:+13174562564',
      ],
    }, finder.ignored_links)
  end

  def test_crawl_url__sort_by_link
    finder = Finder.new sort: :link
    assert finder.crawl_url 'http://mock-server.com/'

    assert_equal({
      'https://doesnt-exist.com' => [
        'http://mock-server.com/',
      ],
      'not_found' => [
        'http://mock-server.com/',
      ],
    }, finder.broken_links)
    assert_equal({
      'mailto:youraddress@yourmailserver.com' => [
        'http://mock-server.com/',
      ],
      'tel:+13174562564' => [
        'http://mock-server.com/',
      ],
    }, finder.ignored_links)
  end

  def test_crawl_url__no_broken_links
    finder = Finder.new
    refute finder.crawl_url('http://mock-server.com/location')

    assert_equal(Hash.new, finder.broken_links)
    assert_equal(Hash.new, finder.ignored_links)
  end

  def test_crawl_url__no_broken_links__sort_by_link
    finder = Finder.new sort: :link
    refute finder.crawl_url('http://mock-server.com/location')

    assert_equal(Hash.new, finder.broken_links)
    assert_equal(Hash.new, finder.ignored_links)
  end

  def test_crawl_url__links_page
    finder = Finder.new
    assert finder.crawl_url 'https://meosch.tk/links.html'
    expected = {
      'https://meosch.tk/links.html' => [
        '/images/non-existent_logo.png',
        '/links.html#anchorthatdoesnotexist',
        '/nonexistent_page.html',
        '/nonexistent_page.html#anchorthatdoesnotexist',

        'https://meos.ch#anchorthandoesnotexist',
        'https://meos.ch/brokenlink',
        'https://meos.ch/brokenlink#anchorthandoesnotexist',
        'https://meos.ch/images/non-existing_logo.png',

        'https://meosch.tk/images/non-existing_logo.png',
        'https://meosch.tk/links.html#anchorthatdoesnotexist',
        'https://meosch.tk/nonexisting_page.html',
        'https://meosch.tk/nonexisting_page.html#anchorthatdoesnotexist',

        'https://thisdomaindoesnotexist-thouthou.com/badpage.html',
        'https://thisdomaindoesnotexist-thouthou.com/badpage.html#anchorthatdoesnotexist',
        'https://thisdomaindoesnotexist-thouthou.com/nonexistentimage.png',
      ]
    }
    assert_equal expected, finder.broken_links
    assert_empty finder.ignored_links
  end

  def test_crawl_url__links_page__sort_by_link
    finder = Finder.new sort: :link
    assert finder.crawl_url 'https://meosch.tk/links.html'
    expected = {
      '/images/non-existent_logo.png' => ['https://meosch.tk/links.html'],
      '/nonexistent_page.html' => ['https://meosch.tk/links.html'],
      '/nonexistent_page.html#anchorthatdoesnotexist' => ['https://meosch.tk/links.html'],
      '/links.html#anchorthatdoesnotexist' => ['https://meosch.tk/links.html'],

      'https://meos.ch/images/non-existing_logo.png' => ['https://meosch.tk/links.html'],
      'https://meos.ch/brokenlink' => ['https://meosch.tk/links.html'],
      'https://meos.ch/brokenlink#anchorthandoesnotexist' => ['https://meosch.tk/links.html'],
      'https://meos.ch#anchorthandoesnotexist' => ['https://meosch.tk/links.html'],

      'https://meosch.tk/images/non-existing_logo.png' => ['https://meosch.tk/links.html'],
      'https://meosch.tk/nonexisting_page.html' => ['https://meosch.tk/links.html'],
      'https://meosch.tk/nonexisting_page.html#anchorthatdoesnotexist' => ['https://meosch.tk/links.html'],
      'https://meosch.tk/links.html#anchorthatdoesnotexist' => ['https://meosch.tk/links.html'],

      'https://thisdomaindoesnotexist-thouthou.com/badpage.html' => ['https://meosch.tk/links.html'],
      'https://thisdomaindoesnotexist-thouthou.com/nonexistentimage.png' => ['https://meosch.tk/links.html'],
      'https://thisdomaindoesnotexist-thouthou.com/badpage.html#anchorthatdoesnotexist' => ['https://meosch.tk/links.html'],
    }
    assert_equal expected, finder.broken_links
    assert_empty finder.ignored_links
  end

  def test_crawl_url__invalid
    finder = Finder.new
    finder.crawl_url 'https://server-error.com'

    flunk
  rescue RuntimeError => ex
    assert_equal 'Invalid URL: https://server-error.com', ex.message
  end

  def test_crawl_page__alias
    finder = Finder.new
    assert finder.respond_to? :crawl_page
  end

  def test_crawl_site
    finder = Finder.new
    broken_links_found, crawled_pages = finder.crawl_site 'http://mock-server.com/'

    assert broken_links_found
    assert_equal([
      'http://mock-server.com/',
      'http://mock-server.com/contact',
      'http://mock-server.com/location',
      'http://mock-server.com/about',
      'http://mock-server.com/not_found',
      'http://mock-server.com/redirect',
      'http://mock-server.com/redirect/2',
    ], crawled_pages)
    assert_equal({
      'http://mock-server.com/' => [
        'https://doesnt-exist.com',
        'not_found',
      ],
      'http://mock-server.com/about' => [
        'https://doesnt-exist.com',
      ],
      'http://mock-server.com/contact' => [
        'https://doesnt-exist.com',
        'not_found',
      ],
    }, finder.broken_links)
    assert_equal({
      'http://mock-server.com/' => [
        'mailto:youraddress@yourmailserver.com',
        'tel:+13174562564',
      ],
      'http://mock-server.com/contact' => [
        'ftp://websiteaddress.com',
      ],
    }, finder.ignored_links)

    # Check it can be run multiple times consecutively without error.
    finder.crawl_site 'http://mock-server.com/'
  end

  def test_crawl_site__sort_by_link
    finder = Finder.new sort: :link
    broken_links_found, crawled_pages = finder.crawl_site 'http://mock-server.com/'

    assert broken_links_found
    assert_equal([
      'http://mock-server.com/',
      'http://mock-server.com/contact',
      'http://mock-server.com/location',
      'http://mock-server.com/about',
      'http://mock-server.com/not_found',
      'http://mock-server.com/redirect',
      'http://mock-server.com/redirect/2',
    ], crawled_pages)
    assert_equal({
      'https://doesnt-exist.com' => [
        'http://mock-server.com/',
        'http://mock-server.com/about',
        'http://mock-server.com/contact',
      ],
      'not_found' => [
        'http://mock-server.com/',
        'http://mock-server.com/contact',
      ],
    }, finder.broken_links)
    assert_equal({
      'ftp://websiteaddress.com' => ['http://mock-server.com/contact'],
      'mailto:youraddress@yourmailserver.com' => ['http://mock-server.com/'],
      'tel:+13174562564' => ['http://mock-server.com/'],
    }, finder.ignored_links)

    # Check it can be run multiple times consecutively without error.
    broken_links_found, _ = finder.crawl_site 'http://mock-server.com/'
    assert broken_links_found
  end
end
