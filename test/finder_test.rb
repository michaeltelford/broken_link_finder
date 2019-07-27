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
    refute_nil finder.instance_variable_get(:@crawler)
  end

  def test_clear_links
    finder = Finder.new
    finder.instance_variable_set :@broken_links, { name: 'foo' }
    finder.instance_variable_set :@ignored_links, { name: 'bar' }
    finder.clear_links

    assert finder.broken_links.empty?
    assert finder.ignored_links.empty?
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
      'http://mock-server.com/contact' => [
        'not_found',
        'https://doesnt-exist.com',
      ],
      'http://mock-server.com/about' => [
        'https://doesnt-exist.com',
      ]
    }, finder.broken_links)
    assert_equal({
      'http://mock-server.com/' => [
        'tel:+13174562564',
        'mailto:youraddress@yourmailserver.com',
      ],
      'http://mock-server.com/contact' => [
        'ftp://websiteaddress.com',
      ],
    }, finder.ignored_links)

    # Check it can be run multiple times consecutively without error.
    finder.crawl_site 'http://mock-server.com/'
  end

  def test_crawl_url
    finder = Finder.new
    assert finder.crawl_url 'http://mock-server.com/'

    assert_equal({
      'http://mock-server.com/' => [
        'https://doesnt-exist.com',
        'not_found',
      ]
    }, finder.broken_links)
    assert_equal({
      'http://mock-server.com/' => [
        'tel:+13174562564',
        'mailto:youraddress@yourmailserver.com',
      ],
    }, finder.ignored_links)
  end

  def test_crawl_url__no_broken_links
    finder = Finder.new
    refute finder.crawl_url('http://mock-server.com/location')

    assert_equal(Hash.new, finder.broken_links)
    assert_equal(Hash.new, finder.ignored_links)
  end

  def test_crawl_url__invalid
    finder = Finder.new
    finder.crawl_url 'https://server-error.com'

    flunk
  rescue RuntimeError => ex
    assert_equal 'Invalid URL: https://server-error.com', ex.message
  end

  def test_crawl_url__links_page
    finder = Finder.new
    assert finder.crawl_url 'https://meosch.tk/links.html'
    expected = {
      'https://meosch.tk/links.html' => [
        'https://meosch.tk/images/non-existing_logo.png',
        'https://meosch.tk/nonexisting_page.html',
        'https://meosch.tk/nonexisting_page.html#anchorthatdoesnotexist',
        'https://meosch.tk/links.html#anchorthatdoesnotexist',

        '/images/non-existent_logo.png',
        '/nonexistent_page.html',
        '/nonexistent_page.html#anchorthatdoesnotexist',
        '/links.html#anchorthatdoesnotexist',

        'https://meos.ch/images/non-existing_logo.png',
        'https://meos.ch/brokenlink',
        'https://meos.ch/brokenlink#anchorthandoesnotexist',
        'https://meos.ch#anchorthandoesnotexist',

        'https://thisdomaindoesnotexist-thouthou.com/badpage.html',
        'https://thisdomaindoesnotexist-thouthou.com/nonexistentimage.png',
        'https://thisdomaindoesnotexist-thouthou.com/badpage.html#anchorthatdoesnotexist',
      ]
    }
    assert_equal expected, finder.broken_links
    assert_empty finder.ignored_links
  end

  def test_crawl_page__alias
    finder = Finder.new
    assert finder.respond_to? :crawl_page
  end
end
