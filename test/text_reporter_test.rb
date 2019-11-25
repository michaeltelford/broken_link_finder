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

    r = BrokenLinkFinder::TextReporter.new @stream, 'http://example.com', :page, broken, ignored
    r.call

    expected = <<~TEXT
      Found 9 broken link(s) across 5 page(s):

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

      Ignored 9 unsupported link(s) across 3 page(s), which you should check manually:

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
      'mailto:blah@gmail.com' => ['http://example.com/about', 'http://example.com/search'],
      'tel:04857233' => ['http://example.com/about', 'http://example.com/contact']
    }
    ignored = {
      'ftp://server.com' => ['http://example.com/', 'http://example.com/about', 'http://example.com/quote', 'http://example.com/search'],
      'smtp://mail-server.com' => ['http://example.com/', 'http://example.com/search']
    }

    r = BrokenLinkFinder::TextReporter.new @stream, 'http://example.com', :link, broken, ignored
    r.call

    expected = <<~TEXT
      Found 3 broken link(s) across 4 page(s):

      The broken link '/doesnt-exist' was found on the following pages:
      http://example.com/quote

      The broken link 'mailto:blah@gmail.com' was found on the following pages:
      http://example.com/about
      http://example.com/search

      The broken link 'tel:04857233' was found on the following pages:
      http://example.com/about
      http://example.com/contact

      Ignored 2 unsupported link(s) across 4 page(s), which you should check manually:

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

    r = BrokenLinkFinder::TextReporter.new @stream, 'http://example.com', :page, broken, ignored
    r.call ignored_verbose: true

    expected = <<~TEXT
      Found 9 broken link(s) across 5 page(s):

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

      Ignored 12 unsupported link(s) across 5 page(s), which you should check manually:

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

    r = BrokenLinkFinder::TextReporter.new @stream, 'http://example.com', :page, broken, ignored
    r.call broken_verbose: false

    expected = <<~TEXT
      Found 8 broken link(s) across 3 page(s):

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

      Ignored 9 unsupported link(s) across 3 page(s), which you should check manually:

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

    r = BrokenLinkFinder::TextReporter.new @stream, 'http://example.com', :page, broken, ignored
    r.call

    expected = <<~TEXT
      Found 9 broken link(s) across 5 page(s):

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

      Ignored 3 unsupported link(s) across 1 page(s), which you should check manually:

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

    r = BrokenLinkFinder::TextReporter.new @stream, 'http://example.com', :page, broken, ignored
    r.call broken_verbose: false

    expected = <<~TEXT
      Found 6 broken link(s) across 3 page(s):

      The following broken links were found on 'http://example.com/':
      /help

      The following broken links were found on 'http://example.com/about':
      /how-to
      http://blah.com

      The following broken links were found on 'http://example.com/contact':
      /doesnt-exist
      blah
      http://doesnt-exist.com

      Ignored 9 unsupported link(s) across 3 page(s), which you should check manually:

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

    r = BrokenLinkFinder::TextReporter.new @stream, 'http://example.com', :page, broken, ignored
    r.call

    expected = <<~TEXT
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

    r = BrokenLinkFinder::TextReporter.new @stream, 'http://example.com', :page, broken, ignored
    r.call

    expected = <<~TEXT
      Found 9 broken link(s) across 5 page(s):

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

    r = BrokenLinkFinder::TextReporter.new @stream, 'http://example.com', :page, broken, ignored
    r.call

    expected = <<~TEXT
      Good news, there are no broken links!

      Ignored 9 unsupported link(s) across 3 page(s), which you should check manually:

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
