# frozen_string_literal: true

require 'helpers/test_helper'

class HTMLReporterTest < TestHelper
  def setup
    @stream = StringIO.new
  end

  def test_sort_by_page
    broken = {
      'http://example.com/' => ['/help'],
      'http://example.com/about' => ['/how-to', 'http://blah.com'],
      'http://example.com/contact' => ['/doesnt-exist', 'http://doesnt-exist.com'],
      'http://example.com/how' => ['blah'],
      'http://example.com/search' => ['/gis', '/map', 'coordinates']
    }
    ignored = {
      'http://example.com/' => ['mailto:blah@gmail.com', 'mailto:foo@bar.com', 'tel:048574362', 'tel:475847222'],
      'http://example.com/about' => ['mailto:blah@gmail.com', 'tel:048574362'],
      'http://example.com/how' => ['mailto:blah@gmail.com', 'smtp://mail.com', 'tel:048574362']
    }
    map = {
      '/help' => 'http://example.com/help',
      '/how-to' => 'http://example.com/how-to',
      'http://blah.com' => 'http://blah.com',
      '/doesnt-exist' => 'http://example.com/doesnt-exist',
      'http://doesnt-exist.com' => 'http://doesnt-exist.com',
      'blah' => 'http://example.com/blah',
      '/gis' => 'http://example.com/gis',
      '/map' => 'http://example.com/map',
      'coordinates' => 'http://example.com/coordinates'
    }
    stats = {
      url: 'http://example.com/',
      pages_crawled: [
        'http://example.com/',
        'http://example.com/about',
        'http://example.com/contact',
        'http://example.com/how',
        'http://example.com/search'
      ],
      num_pages: 5,
      num_links: 15,
      duration: 7.345565
    }

    r = BrokenLinkFinder::HTMLReporter.new @stream, :page, broken, ignored, map, stats
    r.call

    expected = <<~HTML
      <div class=\"broken_link_finder_report\">
      <p class=\"crawl_summary\">Crawled <a href=\"http://example.com/\">http://example.com/</a><br />5 page(s) containing 15 unique link(s) in 7.34 seconds</p>
      <div class=\"broken_links\">
      <p class=\"broken_links_summary\">Found 9 unique broken link(s) across 5 page(s):</p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/\">http://example.com/</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/help\">/help</a><br />
      </p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/about\">http://example.com/about</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/how-to\">/how-to</a><br />
      <a class=\"broken_links_group_item\" href=\"http://blah.com\">http://blah.com</a><br />
      </p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/contact\">http://example.com/contact</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/doesnt-exist\">/doesnt-exist</a><br />
      <a class=\"broken_links_group_item\" href=\"http://doesnt-exist.com\">http://doesnt-exist.com</a><br />
      </p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/how\">http://example.com/how</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/blah\">blah</a><br />
      </p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/search\">http://example.com/search</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/gis\">/gis</a><br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/map\">/map</a><br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/coordinates\">coordinates</a><br />
      </p>
      </div>
      <div class=\"ignored_links\">
      <p class=\"ignored_links_summary\">Ignored 5 unique unsupported link(s) across 3 page(s), which you should check manually:</p>
      <p class=\"ignored_links_group\">
      The following links were ignored on '<a href=\"http://example.com/\">http://example.com/</a>':<br />
      <a class=\"ignored_links_group_item\" href=\"mailto:blah@gmail.com\">mailto:blah@gmail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"mailto:foo@bar.com\">mailto:foo@bar.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"tel:048574362\">tel:048574362</a><br />
      + 1 other link(s), use --verbose to see them all<br />
      </p>
      <p class=\"ignored_links_group\">
      The following links were ignored on '<a href=\"http://example.com/about\">http://example.com/about</a>':<br />
      <a class=\"ignored_links_group_item\" href=\"mailto:blah@gmail.com\">mailto:blah@gmail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"tel:048574362\">tel:048574362</a><br />
      </p>
      <p class=\"ignored_links_group\">
      The following links were ignored on '<a href=\"http://example.com/how\">http://example.com/how</a>':<br />
      <a class=\"ignored_links_group_item\" href=\"mailto:blah@gmail.com\">mailto:blah@gmail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"smtp://mail.com\">smtp://mail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"tel:048574362\">tel:048574362</a><br />
      </p>
      </div>
      </div>
    HTML

    assert_equal expected, @stream.string
  end

  def test_sort_by_link
    broken = {
      '/doesnt-exist' => ['http://example.com/quote'],
      'http://blah.com' => ['http://example.com/about', 'http://example.com/search'],
      'help' => ['http://example.com/about', 'http://example.com/contact']
    }
    ignored = {
      'ftp://server.com' => ['http://example.com/', 'http://example.com/about', 'http://example.com/quote', 'http://example.com/search'],
      'smtp://mail-server.com' => ['http://example.com/', 'http://example.com/search']
    }
    map = {
      '/doesnt-exist' => 'http://example.com/doesnt-exist',
      'http://blah.com' => 'http://blah.com',
      'help' => 'http://example.com/help'
    }
    stats = {
      url: 'http://example.com/',
      pages_crawled: [
        'http://example.com/',
        'http://example.com/about',
        'http://example.com/contact',
        'http://example.com/how',
        'http://example.com/search'
      ],
      num_pages: 5,
      num_links: 15,
      duration: 7.345565
    }

    r = BrokenLinkFinder::HTMLReporter.new @stream, :link, broken, ignored, map, stats
    r.call

    expected = <<~HTML
      <div class=\"broken_link_finder_report\">
      <p class=\"crawl_summary\">Crawled <a href=\"http://example.com/\">http://example.com/</a><br />5 page(s) containing 15 unique link(s) in 7.34 seconds</p>
      <div class=\"broken_links\">
      <p class=\"broken_links_summary\">Found 3 unique broken link(s) across 4 page(s):</p>
      <p class=\"broken_links_group\">
      The broken link '<a href=\"http://example.com/doesnt-exist\">/doesnt-exist</a>' was found on the following pages:<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/quote\">http://example.com/quote</a><br />
      </p>
      <p class=\"broken_links_group\">
      The broken link '<a href=\"http://blah.com\">http://blah.com</a>' was found on the following pages:<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/about\">http://example.com/about</a><br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/search\">http://example.com/search</a><br />
      </p>
      <p class=\"broken_links_group\">
      The broken link '<a href=\"http://example.com/help\">help</a>' was found on the following pages:<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/about\">http://example.com/about</a><br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/contact\">http://example.com/contact</a><br />
      </p>
      </div>
      <div class=\"ignored_links\">
      <p class=\"ignored_links_summary\">Ignored 2 unique unsupported link(s) across 4 page(s), which you should check manually:</p>
      <p class=\"ignored_links_group\">
      The link '<a href=\"ftp://server.com\">ftp://server.com</a>' was ignored on the following pages:<br />
      <a class=\"ignored_links_group_item\" href=\"http://example.com/\">http://example.com/</a><br />
      <a class=\"ignored_links_group_item\" href=\"http://example.com/about\">http://example.com/about</a><br />
      <a class=\"ignored_links_group_item\" href=\"http://example.com/quote\">http://example.com/quote</a><br />
      + 1 other page(s), use --verbose to see them all<br />
      </p>
      <p class=\"ignored_links_group\">
      The link '<a href=\"smtp://mail-server.com\">smtp://mail-server.com</a>' was ignored on the following pages:<br />
      <a class=\"ignored_links_group_item\" href=\"http://example.com/\">http://example.com/</a><br />
      <a class=\"ignored_links_group_item\" href=\"http://example.com/search\">http://example.com/search</a><br />
      </p>
      </div>
      </div>
    HTML

    assert_equal expected, @stream.string
  end

  def test_sort_by_page__verbose
    broken = {
      'http://example.com/' => ['/help'],
      'http://example.com/about' => ['/how-to', 'http://blah.com'],
      'http://example.com/contact' => ['/doesnt-exist', 'http://doesnt-exist.com'],
      'http://example.com/how' => ['blah'],
      'http://example.com/search' => ['/gis', '/map', 'coordinates']
    }
    ignored = {
      'http://example.com/' => ['mailto:blah@gmail.com', 'mailto:foo@bar.com', 'tel:048574362', 'tel:475847222'],
      'http://example.com/about' => ['mailto:blah@gmail.com', 'tel:048574362'],
      'http://example.com/ftp' => ['ftp://user:password@server.com/dir'],
      'http://example.com/how' => ['mailto:blah@gmail.com', 'smtp://mail.com', 'tel:048574362'],
      'http://example.com/quote' => ['mailto:blah@gmail.com', 'tel:048574362']
    }
    map = {
      '/help' => 'http://example.com/help',
      '/how-to' => 'http://example.com/how-to',
      'http://blah.com' => 'http://blah.com',
      '/doesnt-exist' => 'http://example.com/doesnt-exist',
      'http://doesnt-exist.com' => 'http://doesnt-exist.com',
      'blah' => 'http://example.com/blah',
      '/gis' => 'http://example.com/gis',
      '/map' => 'http://example.com/map',
      'coordinates' => 'http://example.com/coordinates'
    }
    stats = {
      url: 'http://example.com/',
      pages_crawled: [
        'http://example.com/',
        'http://example.com/about',
        'http://example.com/contact',
        'http://example.com/how',
        'http://example.com/search'
      ],
      num_pages: 5,
      num_links: 15,
      duration: 7.345565
    }

    r = BrokenLinkFinder::HTMLReporter.new @stream, :page, broken, ignored, map, stats
    r.call ignored_verbose: true

    expected = <<~HTML
      <div class=\"broken_link_finder_report\">
      <p class=\"crawl_summary\">Crawled <a href=\"http://example.com/\">http://example.com/</a><br />5 page(s) containing 15 unique link(s) in 7.34 seconds</p>
      <div class=\"broken_links\">
      <p class=\"broken_links_summary\">Found 9 unique broken link(s) across 5 page(s):</p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/\">http://example.com/</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/help\">/help</a><br />
      </p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/about\">http://example.com/about</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/how-to\">/how-to</a><br />
      <a class=\"broken_links_group_item\" href=\"http://blah.com\">http://blah.com</a><br />
      </p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/contact\">http://example.com/contact</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/doesnt-exist\">/doesnt-exist</a><br />
      <a class=\"broken_links_group_item\" href=\"http://doesnt-exist.com\">http://doesnt-exist.com</a><br />
      </p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/how\">http://example.com/how</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/blah\">blah</a><br />
      </p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/search\">http://example.com/search</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/gis\">/gis</a><br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/map\">/map</a><br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/coordinates\">coordinates</a><br />
      </p>
      </div>
      <div class=\"ignored_links\">
      <p class=\"ignored_links_summary\">Ignored 6 unique unsupported link(s) across 5 page(s), which you should check manually:</p>
      <p class=\"ignored_links_group\">
      The following links were ignored on '<a href=\"http://example.com/\">http://example.com/</a>':<br />
      <a class=\"ignored_links_group_item\" href=\"mailto:blah@gmail.com\">mailto:blah@gmail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"mailto:foo@bar.com\">mailto:foo@bar.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"tel:048574362\">tel:048574362</a><br />
      <a class=\"ignored_links_group_item\" href=\"tel:475847222\">tel:475847222</a><br />
      </p>
      <p class=\"ignored_links_group\">
      The following links were ignored on '<a href=\"http://example.com/about\">http://example.com/about</a>':<br />
      <a class=\"ignored_links_group_item\" href=\"mailto:blah@gmail.com\">mailto:blah@gmail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"tel:048574362\">tel:048574362</a><br />
      </p>
      <p class=\"ignored_links_group\">
      The following links were ignored on '<a href=\"http://example.com/ftp\">http://example.com/ftp</a>':<br />
      <a class=\"ignored_links_group_item\" href=\"ftp://user:password@server.com/dir\">ftp://user:password@server.com/dir</a><br />
      </p>
      <p class=\"ignored_links_group\">
      The following links were ignored on '<a href=\"http://example.com/how\">http://example.com/how</a>':<br />
      <a class=\"ignored_links_group_item\" href=\"mailto:blah@gmail.com\">mailto:blah@gmail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"smtp://mail.com\">smtp://mail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"tel:048574362\">tel:048574362</a><br />
      </p>
      <p class=\"ignored_links_group\">
      The following links were ignored on '<a href=\"http://example.com/quote\">http://example.com/quote</a>':<br />
      <a class=\"ignored_links_group_item\" href=\"mailto:blah@gmail.com\">mailto:blah@gmail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"tel:048574362\">tel:048574362</a><br />
      </p>
      </div>
      </div>
    HTML

    assert_equal expected, @stream.string
  end

  def test_sort_by_page__concise
    broken = {
      'http://example.com/' => ['/help'],
      'http://example.com/about' => ['/how-to', 'http://blah.com'],
      'http://example.com/contact' => ['/doesnt-exist', '/gis', '/map', 'coordinates', 'http://doesnt-exist.com']
    }
    ignored = {
      'http://example.com/' => ['mailto:blah@gmail.com', 'mailto:foo@bar.com', 'tel:048574362', 'tel:475847222'],
      'http://example.com/about' => ['mailto:blah@gmail.com', 'tel:048574362'],
      'http://example.com/how' => ['mailto:blah@gmail.com', 'smtp://mail.com', 'tel:048574362']
    }
    map = {
      '/help' => 'http://example.com/help',
      '/how-to' => 'http://example.com/how-to',
      'http://blah.com' => 'http://blah.com',
      '/doesnt-exist' => 'http://example.com/doesnt-exist',
      'http://doesnt-exist.com' => 'http://doesnt-exist.com',
      'blah' => 'http://example.com/blah',
      '/gis' => 'http://example.com/gis',
      '/map' => 'http://example.com/map',
      'coordinates' => 'http://example.com/coordinates'
    }
    stats = {
      url: 'http://example.com/',
      pages_crawled: [
        'http://example.com/',
        'http://example.com/about',
        'http://example.com/contact',
        'http://example.com/how',
        'http://example.com/search'
      ],
      num_pages: 5,
      num_links: 15,
      duration: 7.345565
    }

    r = BrokenLinkFinder::HTMLReporter.new @stream, :page, broken, ignored, map, stats
    r.call broken_verbose: false

    expected = <<~HTML
      <div class=\"broken_link_finder_report\">
      <p class=\"crawl_summary\">Crawled <a href=\"http://example.com/\">http://example.com/</a><br />5 page(s) containing 15 unique link(s) in 7.34 seconds</p>
      <div class=\"broken_links\">
      <p class=\"broken_links_summary\">Found 8 unique broken link(s) across 3 page(s):</p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/\">http://example.com/</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/help\">/help</a><br />
      </p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/about\">http://example.com/about</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/how-to\">/how-to</a><br />
      <a class=\"broken_links_group_item\" href=\"http://blah.com\">http://blah.com</a><br />
      </p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/contact\">http://example.com/contact</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/doesnt-exist\">/doesnt-exist</a><br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/gis\">/gis</a><br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/map\">/map</a><br />
      + 2 other link(s), remove --concise to see them all<br />
      </p>
      </div>
      <div class=\"ignored_links\">
      <p class=\"ignored_links_summary\">Ignored 5 unique unsupported link(s) across 3 page(s), which you should check manually:</p>
      <p class=\"ignored_links_group\">
      The following links were ignored on '<a href=\"http://example.com/\">http://example.com/</a>':<br />
      <a class=\"ignored_links_group_item\" href=\"mailto:blah@gmail.com\">mailto:blah@gmail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"mailto:foo@bar.com\">mailto:foo@bar.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"tel:048574362\">tel:048574362</a><br />
      + 1 other link(s), use --verbose to see them all<br />
      </p>
      <p class=\"ignored_links_group\">
      The following links were ignored on '<a href=\"http://example.com/about\">http://example.com/about</a>':<br />
      <a class=\"ignored_links_group_item\" href=\"mailto:blah@gmail.com\">mailto:blah@gmail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"tel:048574362\">tel:048574362</a><br />
      </p>
      <p class=\"ignored_links_group\">
      The following links were ignored on '<a href=\"http://example.com/how\">http://example.com/how</a>':<br />
      <a class=\"ignored_links_group_item\" href=\"mailto:blah@gmail.com\">mailto:blah@gmail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"smtp://mail.com\">smtp://mail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"tel:048574362\">tel:048574362</a><br />
      </p>
      </div>
      </div>
    HTML

    assert_equal expected, @stream.string
  end

  def test_sort_by_page__minimum_ignored
    broken = {
      'http://example.com/' => ['/help'],
      'http://example.com/about' => ['/how-to', 'http://blah.com'],
      'http://example.com/contact' => ['/doesnt-exist', 'http://doesnt-exist.com'],
      'http://example.com/how' => ['blah'],
      'http://example.com/search' => ['/gis', '/map', 'coordinates']
    }
    ignored = {
      'http://example.com/' => ['mailto:blah@gmail.com', 'mailto:foo@bar.com', 'tel:048574362']
    }
    map = {
      '/help' => 'http://example.com/help',
      '/how-to' => 'http://example.com/how-to',
      'http://blah.com' => 'http://blah.com',
      '/doesnt-exist' => 'http://example.com/doesnt-exist',
      'http://doesnt-exist.com' => 'http://doesnt-exist.com',
      'blah' => 'http://example.com/blah',
      '/gis' => 'http://example.com/gis',
      '/map' => 'http://example.com/map',
      'coordinates' => 'http://example.com/coordinates'
    }
    stats = {
      url: 'http://example.com/',
      pages_crawled: [
        'http://example.com/',
        'http://example.com/about',
        'http://example.com/contact',
        'http://example.com/how',
        'http://example.com/search'
      ],
      num_pages: 5,
      num_links: 15,
      duration: 7.345565
    }

    r = BrokenLinkFinder::HTMLReporter.new @stream, :page, broken, ignored, map, stats
    r.call

    expected = <<~HTML
      <div class=\"broken_link_finder_report\">
      <p class=\"crawl_summary\">Crawled <a href=\"http://example.com/\">http://example.com/</a><br />5 page(s) containing 15 unique link(s) in 7.34 seconds</p>
      <div class=\"broken_links\">
      <p class=\"broken_links_summary\">Found 9 unique broken link(s) across 5 page(s):</p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/\">http://example.com/</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/help\">/help</a><br />
      </p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/about\">http://example.com/about</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/how-to\">/how-to</a><br />
      <a class=\"broken_links_group_item\" href=\"http://blah.com\">http://blah.com</a><br />
      </p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/contact\">http://example.com/contact</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/doesnt-exist\">/doesnt-exist</a><br />
      <a class=\"broken_links_group_item\" href=\"http://doesnt-exist.com\">http://doesnt-exist.com</a><br />
      </p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/how\">http://example.com/how</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/blah\">blah</a><br />
      </p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/search\">http://example.com/search</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/gis\">/gis</a><br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/map\">/map</a><br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/coordinates\">coordinates</a><br />
      </p>
      </div>
      <div class=\"ignored_links\">
      <p class=\"ignored_links_summary\">Ignored 3 unique unsupported link(s) across 1 page(s), which you should check manually:</p>
      <p class=\"ignored_links_group\">
      The following links were ignored on '<a href=\"http://example.com/\">http://example.com/</a>':<br />
      <a class=\"ignored_links_group_item\" href=\"mailto:blah@gmail.com\">mailto:blah@gmail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"mailto:foo@bar.com\">mailto:foo@bar.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"tel:048574362\">tel:048574362</a><br />
      </p>
      </div>
      </div>
    HTML

    assert_equal expected, @stream.string
  end

  def test_sort_by_page__concise_with_minimum_broken
    broken = {
      'http://example.com/' => ['/help'],
      'http://example.com/about' => ['/how-to', 'http://blah.com'],
      'http://example.com/contact' => ['/doesnt-exist', 'blah', 'http://doesnt-exist.com']
    }
    ignored = {
      'http://example.com/' => ['mailto:blah@gmail.com', 'mailto:foo@bar.com', 'tel:048574362', 'tel:475847222'],
      'http://example.com/about' => ['mailto:blah@gmail.com', 'tel:048574362'],
      'http://example.com/how' => ['mailto:blah@gmail.com', 'smtp://mail.com', 'tel:048574362']
    }
    map = {
      '/help' => 'http://example.com/help',
      '/how-to' => 'http://example.com/how-to',
      'http://blah.com' => 'http://blah.com',
      '/doesnt-exist' => 'http://example.com/doesnt-exist',
      'http://doesnt-exist.com' => 'http://doesnt-exist.com',
      'blah' => 'http://example.com/blah',
      '/gis' => 'http://example.com/gis',
      '/map' => 'http://example.com/map',
      'coordinates' => 'http://example.com/coordinates'
    }
    stats = {
      url: 'http://example.com/',
      pages_crawled: [
        'http://example.com/',
        'http://example.com/about',
        'http://example.com/contact',
        'http://example.com/how',
        'http://example.com/search'
      ],
      num_pages: 5,
      num_links: 15,
      duration: 7.345565
    }

    r = BrokenLinkFinder::HTMLReporter.new @stream, :page, broken, ignored, map, stats
    r.call broken_verbose: false

    expected = <<~HTML
      <div class=\"broken_link_finder_report\">
      <p class=\"crawl_summary\">Crawled <a href=\"http://example.com/\">http://example.com/</a><br />5 page(s) containing 15 unique link(s) in 7.34 seconds</p>
      <div class=\"broken_links\">
      <p class=\"broken_links_summary\">Found 6 unique broken link(s) across 3 page(s):</p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/\">http://example.com/</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/help\">/help</a><br />
      </p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/about\">http://example.com/about</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/how-to\">/how-to</a><br />
      <a class=\"broken_links_group_item\" href=\"http://blah.com\">http://blah.com</a><br />
      </p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/contact\">http://example.com/contact</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/doesnt-exist\">/doesnt-exist</a><br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/blah\">blah</a><br />
      <a class=\"broken_links_group_item\" href=\"http://doesnt-exist.com\">http://doesnt-exist.com</a><br />
      </p>
      </div>
      <div class=\"ignored_links\">
      <p class=\"ignored_links_summary\">Ignored 5 unique unsupported link(s) across 3 page(s), which you should check manually:</p>
      <p class=\"ignored_links_group\">
      The following links were ignored on '<a href=\"http://example.com/\">http://example.com/</a>':<br />
      <a class=\"ignored_links_group_item\" href=\"mailto:blah@gmail.com\">mailto:blah@gmail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"mailto:foo@bar.com\">mailto:foo@bar.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"tel:048574362\">tel:048574362</a><br />
      + 1 other link(s), use --verbose to see them all<br />
      </p>
      <p class=\"ignored_links_group\">
      The following links were ignored on '<a href=\"http://example.com/about\">http://example.com/about</a>':<br />
      <a class=\"ignored_links_group_item\" href=\"mailto:blah@gmail.com\">mailto:blah@gmail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"tel:048574362\">tel:048574362</a><br />
      </p>
      <p class=\"ignored_links_group\">
      The following links were ignored on '<a href=\"http://example.com/how\">http://example.com/how</a>':<br />
      <a class=\"ignored_links_group_item\" href=\"mailto:blah@gmail.com\">mailto:blah@gmail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"smtp://mail.com\">smtp://mail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"tel:048574362\">tel:048574362</a><br />
      </p>
      </div>
      </div>
    HTML

    assert_equal expected, @stream.string
  end

  def test_no_broken_links
    broken = {}
    ignored = {}
    map = {}
    stats = {
      url: 'http://example.com/',
      pages_crawled: [
        'http://example.com/',
        'http://example.com/about',
        'http://example.com/contact',
        'http://example.com/how',
        'http://example.com/search'
      ],
      num_pages: 5,
      num_links: 15,
      duration: 7.345565
    }

    r = BrokenLinkFinder::HTMLReporter.new @stream, :page, broken, ignored, map, stats
    r.call

    expected = <<~HTML
      <div class=\"broken_link_finder_report\">
      <p class=\"crawl_summary\">Crawled <a href=\"http://example.com/\">http://example.com/</a><br />5 page(s) containing 15 unique link(s) in 7.34 seconds</p>
      <div class=\"broken_links\">
      <p class=\"broken_links_summary\">Good news, there are no broken links!</p>
      </div>
      <div class=\"ignored_links\">
      </div>
      </div>
    HTML

    assert_equal expected, @stream.string
  end

  def test_no_ignored_links
    broken = {
      'http://example.com/' => ['/help'],
      'http://example.com/about' => ['/how-to', 'http://blah.com'],
      'http://example.com/contact' => ['/doesnt-exist', 'http://doesnt-exist.com'],
      'http://example.com/how' => ['blah'],
      'http://example.com/search' => ['/gis', '/map', 'coordinates']
    }
    ignored = {}
    map = {
      '/help' => 'http://example.com/help',
      '/how-to' => 'http://example.com/how-to',
      'http://blah.com' => 'http://blah.com',
      '/doesnt-exist' => 'http://example.com/doesnt-exist',
      'http://doesnt-exist.com' => 'http://doesnt-exist.com',
      'blah' => 'http://example.com/blah',
      '/gis' => 'http://example.com/gis',
      '/map' => 'http://example.com/map',
      'coordinates' => 'http://example.com/coordinates'
    }
    stats = {
      url: 'http://example.com/',
      pages_crawled: [
        'http://example.com/',
        'http://example.com/about',
        'http://example.com/contact',
        'http://example.com/how',
        'http://example.com/search',
        'http://example.com/blah',
        'http://example.com/gis',
      ],
      num_pages: 7,
      num_links: 21,
      duration: 8.125565
    }

    r = BrokenLinkFinder::HTMLReporter.new @stream, :page, broken, ignored, map, stats
    r.call

    expected = <<~HTML
      <div class=\"broken_link_finder_report\">
      <p class=\"crawl_summary\">Crawled <a href=\"http://example.com/\">http://example.com/</a><br />7 page(s) containing 21 unique link(s) in 8.12 seconds</p>
      <div class=\"broken_links\">
      <p class=\"broken_links_summary\">Found 9 unique broken link(s) across 5 page(s):</p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/\">http://example.com/</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/help\">/help</a><br />
      </p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/about\">http://example.com/about</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/how-to\">/how-to</a><br />
      <a class=\"broken_links_group_item\" href=\"http://blah.com\">http://blah.com</a><br />
      </p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/contact\">http://example.com/contact</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/doesnt-exist\">/doesnt-exist</a><br />
      <a class=\"broken_links_group_item\" href=\"http://doesnt-exist.com\">http://doesnt-exist.com</a><br />
      </p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/how\">http://example.com/how</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/blah\">blah</a><br />
      </p>
      <p class=\"broken_links_group\">
      The following broken links were found on '<a href=\"http://example.com/search\">http://example.com/search</a>':<br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/gis\">/gis</a><br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/map\">/map</a><br />
      <a class=\"broken_links_group_item\" href=\"http://example.com/coordinates\">coordinates</a><br />
      </p>
      </div>
      <div class=\"ignored_links\">
      </div>
      </div>
    HTML

    assert_equal expected, @stream.string
  end

  def test_no_broken_links__with_ignored_links
    broken = {}
    ignored = {
      'http://example.com/' => ['mailto:blah@gmail.com', 'mailto:foo@bar.com', 'tel:048574362', 'tel:475847222'],
      'http://example.com/about' => ['mailto:blah@gmail.com', 'tel:048574362'],
      'http://example.com/how' => ['mailto:blah@gmail.com', 'smtp://mail.com', 'tel:048574362']
    }
    map = {}
    stats = {
      url: 'http://example.com/',
      pages_crawled: [
        'http://example.com/',
        'http://example.com/about',
        'http://example.com/contact',
        'http://example.com/how',
        'http://example.com/search'
      ],
      num_pages: 5,
      num_links: 15,
      duration: 7.345565
    }

    r = BrokenLinkFinder::HTMLReporter.new @stream, :page, broken, ignored, map, stats
    r.call

    expected = <<~HTML
      <div class=\"broken_link_finder_report\">
      <p class=\"crawl_summary\">Crawled <a href=\"http://example.com/\">http://example.com/</a><br />5 page(s) containing 15 unique link(s) in 7.34 seconds</p>
      <div class=\"broken_links\">
      <p class=\"broken_links_summary\">Good news, there are no broken links!</p>
      </div>
      <div class=\"ignored_links\">
      <p class=\"ignored_links_summary\">Ignored 5 unique unsupported link(s) across 3 page(s), which you should check manually:</p>
      <p class=\"ignored_links_group\">
      The following links were ignored on '<a href=\"http://example.com/\">http://example.com/</a>':<br />
      <a class=\"ignored_links_group_item\" href=\"mailto:blah@gmail.com\">mailto:blah@gmail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"mailto:foo@bar.com\">mailto:foo@bar.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"tel:048574362\">tel:048574362</a><br />
      + 1 other link(s), use --verbose to see them all<br />
      </p>
      <p class=\"ignored_links_group\">
      The following links were ignored on '<a href=\"http://example.com/about\">http://example.com/about</a>':<br />
      <a class=\"ignored_links_group_item\" href=\"mailto:blah@gmail.com\">mailto:blah@gmail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"tel:048574362\">tel:048574362</a><br />
      </p>
      <p class=\"ignored_links_group\">
      The following links were ignored on '<a href=\"http://example.com/how\">http://example.com/how</a>':<br />
      <a class=\"ignored_links_group_item\" href=\"mailto:blah@gmail.com\">mailto:blah@gmail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"smtp://mail.com\">smtp://mail.com</a><br />
      <a class=\"ignored_links_group_item\" href=\"tel:048574362\">tel:048574362</a><br />
      </p>
      </div>
      </div>
    HTML

    assert_equal expected, @stream.string
  end

  def test_unparsable_links
    broken = {
      'http://unparsable.com' => [
        'http://',
        'https://',
        'https://server-error.com'
      ]
    }
    ignored = {}
    map = {
      'http://' => 'http://',
      'https://' => 'https://',
      'https://server-error.com' => 'https://server-error.com'
    }
    stats = {
      url: 'http://unparsable.com',
      pages_crawled: ['http://unparsable.com'],
      num_pages: 1,
      num_links: 4,
      duration: 2.44506
    }

    r = BrokenLinkFinder::HTMLReporter.new @stream, :page, broken, ignored, map, stats
    r.call

    expected = <<~HTML
    <div class=\"broken_link_finder_report\">
    <p class=\"crawl_summary\">Crawled <a href=\"http://unparsable.com\">http://unparsable.com</a><br />1 page(s) containing 4 unique link(s) in 2.44 seconds</p>
    <div class=\"broken_links\">
    <p class=\"broken_links_summary\">Found 3 unique broken link(s) across 1 page(s):</p>
    <p class=\"broken_links_group\">
    The following broken links were found on '<a href=\"http://unparsable.com\">http://unparsable.com</a>':<br />
    <a class=\"broken_links_group_item\" href=\"http://\">http://</a><br />
    <a class=\"broken_links_group_item\" href=\"https://\">https://</a><br />
    <a class=\"broken_links_group_item\" href=\"https://server-error.com\">https://server-error.com</a><br />
    </p>
    </div>
    <div class=\"ignored_links\">
    </div>
    </div>
    HTML

    assert_equal expected, @stream.string
  end
end
