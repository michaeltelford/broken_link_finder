require 'helpers/test_helper'

class FinderTest < TestHelper
  def test_initialize
    finder = Finder.new

    assert_equal Hash.new, finder.broken_links
    refute_nil finder.instance_variable_get(:@crawler)
  end

  def test_clear_broken_links
    finder = Finder.new
    finder.instance_variable_set :@broken_links, { name: 'mick' }
    finder.clear_broken_links

    assert finder.broken_links.empty?
  end

  def test_crawl_site
    finder = Finder.new
    assert finder.crawl_site $mock_server

    assert_equal({ 
      $mock_server => [
        $mock_server + $mock_invalid_link,
        $mock_invalid_url
      ],
      $mock_server + 'contact' => [
        $mock_server + $mock_invalid_link,
        $mock_invalid_url
      ],
      $mock_server + 'about' => [
        $mock_invalid_url
      ]
    }, finder.broken_links)
  end

  def test_crawl_url
    finder = Finder.new
    assert finder.crawl_url $mock_server

    assert_equal({ 
      $mock_server => [
        $mock_server + $mock_invalid_link,
        $mock_invalid_url
      ]
    }, finder.broken_links)
  end

  def test_crawl_url__no_broken_links
    finder = Finder.new
    refute finder.crawl_url($mock_server + 'location')

    assert_equal(Hash.new, finder.broken_links)
  end

  def test_crawl_url__invalid
    finder = Finder.new
    finder.crawl_url $mock_invalid_url
    
    flunk
  rescue RuntimeError => ex
    assert_equal "Invalid URL: #{$mock_invalid_url}", ex.message
  end
end
