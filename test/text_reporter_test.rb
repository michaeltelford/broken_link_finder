# frozen_string_literal: true

require 'helpers/test_helper'

class TextReporterTest < TestHelper
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

    r = BrokenLinkFinder::TextReporter.new @stream, :page, broken, ignored, {}, stats
    r.call

    expected = <<~TEXT
      Crawled http://example.com/ (5 page(s) in 7.34 seconds)

      Found 9 unique broken link(s) across 5 page(s):

      The following broken links were found on 'http://example.com/':
      /help

      The following broken links were found on 'http://example.com/about':
      /how-to
      http://blah.com

      The following broken links were found on 'http://example.com/contact':
      /doesnt-exist
      http://doesnt-exist.com

      The following broken links were found on 'http://example.com/how':
      blah

      The following broken links were found on 'http://example.com/search':
      /gis
      /map
      coordinates

      Ignored 5 unique unsupported link(s) across 3 page(s), which you should check manually:

      The following links were ignored on 'http://example.com/':
      mailto:blah@gmail.com
      mailto:foo@bar.com
      tel:048574362
      + 1 other link(s), use --verbose to see them all

      The following links were ignored on 'http://example.com/about':
      mailto:blah@gmail.com
      tel:048574362

      The following links were ignored on 'http://example.com/how':
      mailto:blah@gmail.com
      smtp://mail.com
      tel:048574362
    TEXT

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

    r = BrokenLinkFinder::TextReporter.new @stream, :link, broken, ignored, {}, stats
    r.call

    expected = <<~TEXT
      Crawled http://example.com/ (5 page(s) in 7.34 seconds)

      Found 3 unique broken link(s) across 4 page(s):

      The broken link '/doesnt-exist' was found on the following pages:
      http://example.com/quote

      The broken link 'http://blah.com' was found on the following pages:
      http://example.com/about
      http://example.com/search

      The broken link 'help' was found on the following pages:
      http://example.com/about
      http://example.com/contact

      Ignored 2 unique unsupported link(s) across 4 page(s), which you should check manually:

      The link 'ftp://server.com' was ignored on the following pages:
      http://example.com/
      http://example.com/about
      http://example.com/quote
      + 1 other page(s), use --verbose to see them all

      The link 'smtp://mail-server.com' was ignored on the following pages:
      http://example.com/
      http://example.com/search
    TEXT

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

    r = BrokenLinkFinder::TextReporter.new @stream, :page, broken, ignored, {}, stats
    r.call ignored_verbose: true

    expected = <<~TEXT
      Crawled http://example.com/ (5 page(s) in 7.34 seconds)

      Found 9 unique broken link(s) across 5 page(s):

      The following broken links were found on 'http://example.com/':
      /help

      The following broken links were found on 'http://example.com/about':
      /how-to
      http://blah.com

      The following broken links were found on 'http://example.com/contact':
      /doesnt-exist
      http://doesnt-exist.com

      The following broken links were found on 'http://example.com/how':
      blah

      The following broken links were found on 'http://example.com/search':
      /gis
      /map
      coordinates

      Ignored 6 unique unsupported link(s) across 5 page(s), which you should check manually:

      The following links were ignored on 'http://example.com/':
      mailto:blah@gmail.com
      mailto:foo@bar.com
      tel:048574362
      tel:475847222

      The following links were ignored on 'http://example.com/about':
      mailto:blah@gmail.com
      tel:048574362

      The following links were ignored on 'http://example.com/ftp':
      ftp://user:password@server.com/dir

      The following links were ignored on 'http://example.com/how':
      mailto:blah@gmail.com
      smtp://mail.com
      tel:048574362

      The following links were ignored on 'http://example.com/quote':
      mailto:blah@gmail.com
      tel:048574362
    TEXT

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

    r = BrokenLinkFinder::TextReporter.new @stream, :page, broken, ignored, {}, stats
    r.call broken_verbose: false

    expected = <<~TEXT
      Crawled http://example.com/ (5 page(s) in 7.34 seconds)

      Found 8 unique broken link(s) across 3 page(s):

      The following broken links were found on 'http://example.com/':
      /help

      The following broken links were found on 'http://example.com/about':
      /how-to
      http://blah.com

      The following broken links were found on 'http://example.com/contact':
      /doesnt-exist
      /gis
      /map
      + 2 other link(s), remove --concise to see them all

      Ignored 5 unique unsupported link(s) across 3 page(s), which you should check manually:

      The following links were ignored on 'http://example.com/':
      mailto:blah@gmail.com
      mailto:foo@bar.com
      tel:048574362
      + 1 other link(s), use --verbose to see them all

      The following links were ignored on 'http://example.com/about':
      mailto:blah@gmail.com
      tel:048574362

      The following links were ignored on 'http://example.com/how':
      mailto:blah@gmail.com
      smtp://mail.com
      tel:048574362
    TEXT

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

    r = BrokenLinkFinder::TextReporter.new @stream, :page, broken, ignored, {}, stats
    r.call

    expected = <<~TEXT
      Crawled http://example.com/ (5 page(s) in 7.34 seconds)

      Found 9 unique broken link(s) across 5 page(s):

      The following broken links were found on 'http://example.com/':
      /help

      The following broken links were found on 'http://example.com/about':
      /how-to
      http://blah.com

      The following broken links were found on 'http://example.com/contact':
      /doesnt-exist
      http://doesnt-exist.com

      The following broken links were found on 'http://example.com/how':
      blah

      The following broken links were found on 'http://example.com/search':
      /gis
      /map
      coordinates

      Ignored 3 unique unsupported link(s) across 1 page(s), which you should check manually:

      The following links were ignored on 'http://example.com/':
      mailto:blah@gmail.com
      mailto:foo@bar.com
      tel:048574362
    TEXT

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

    r = BrokenLinkFinder::TextReporter.new @stream, :page, broken, ignored, {}, stats
    r.call

    expected = <<~TEXT
      Crawled http://example.com/ (5 page(s) in 7.34 seconds)

      Found 6 unique broken link(s) across 3 page(s):

      The following broken links were found on 'http://example.com/':
      /help

      The following broken links were found on 'http://example.com/about':
      /how-to
      http://blah.com

      The following broken links were found on 'http://example.com/contact':
      /doesnt-exist
      blah
      http://doesnt-exist.com

      Ignored 5 unique unsupported link(s) across 3 page(s), which you should check manually:

      The following links were ignored on 'http://example.com/':
      mailto:blah@gmail.com
      mailto:foo@bar.com
      tel:048574362
      + 1 other link(s), use --verbose to see them all

      The following links were ignored on 'http://example.com/about':
      mailto:blah@gmail.com
      tel:048574362

      The following links were ignored on 'http://example.com/how':
      mailto:blah@gmail.com
      smtp://mail.com
      tel:048574362
    TEXT

    assert_equal expected, @stream.string
  end

  def test_no_broken_links
    broken = {}
    ignored = {}
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

    r = BrokenLinkFinder::TextReporter.new @stream, :page, broken, ignored, {}, stats
    r.call

    expected = <<~TEXT
      Crawled http://example.com/ (5 page(s) in 7.34 seconds)

      Good news, there are no broken links!
    TEXT

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

    r = BrokenLinkFinder::TextReporter.new @stream, :page, broken, ignored, {}, stats
    r.call

    expected = <<~TEXT
      Crawled http://example.com/ (5 page(s) in 7.34 seconds)

      Found 9 unique broken link(s) across 5 page(s):

      The following broken links were found on 'http://example.com/':
      /help

      The following broken links were found on 'http://example.com/about':
      /how-to
      http://blah.com

      The following broken links were found on 'http://example.com/contact':
      /doesnt-exist
      http://doesnt-exist.com

      The following broken links were found on 'http://example.com/how':
      blah

      The following broken links were found on 'http://example.com/search':
      /gis
      /map
      coordinates
    TEXT

    assert_equal expected, @stream.string
  end

  def test_no_broken_links__with_ignored_links
    broken = {}
    ignored = {
      'http://example.com/' => ['mailto:blah@gmail.com', 'mailto:foo@bar.com', 'tel:048574362', 'tel:475847222'],
      'http://example.com/about' => ['mailto:blah@gmail.com', 'tel:048574362'],
      'http://example.com/how' => ['mailto:blah@gmail.com', 'smtp://mail.com', 'tel:048574362']
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

    r = BrokenLinkFinder::TextReporter.new @stream, :page, broken, ignored, {}, stats
    r.call

    expected = <<~TEXT
      Crawled http://example.com/ (5 page(s) in 7.34 seconds)

      Good news, there are no broken links!

      Ignored 5 unique unsupported link(s) across 3 page(s), which you should check manually:

      The following links were ignored on 'http://example.com/':
      mailto:blah@gmail.com
      mailto:foo@bar.com
      tel:048574362
      + 1 other link(s), use --verbose to see them all

      The following links were ignored on 'http://example.com/about':
      mailto:blah@gmail.com
      tel:048574362

      The following links were ignored on 'http://example.com/how':
      mailto:blah@gmail.com
      smtp://mail.com
      tel:048574362
    TEXT

    assert_equal expected, @stream.string
  end
end
