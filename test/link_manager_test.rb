# frozen_string_literal: true

require 'helpers/test_helper'

class LinkManagerTest < TestHelper
  def test_initialize
    manager = LinkManager.new :page

    assert_equal :page, manager.instance_variable_get(:@sort)
    refute_nil manager.instance_variable_get(:@lock)
    assert_empty manager.broken_links
    assert_empty manager.ignored_links
    assert_empty manager.crawl_stats
    assert_empty manager.broken_link_map
    assert_empty manager.all_broken_links
    assert_empty manager.all_intact_links
    assert_empty manager.all_ignored_links

    assert_raises(StandardError) { LinkManager.new :blah }
  end

  def test_empty
    manager = LinkManager.new :page

    assert_empty manager.broken_links
    assert_empty manager.ignored_links
    assert_empty manager.crawl_stats
    assert_empty manager.broken_link_map
    assert_empty manager.all_broken_links
    assert_empty manager.all_intact_links
    assert_empty manager.all_ignored_links
  end

  def test_append_broken_link
    doc = Wgit::Document.new 'http://example.com'.to_url
    link = '/about.html'.to_url

    manager = LinkManager.new :page
    manager.append_broken_link doc, link

    refute_empty manager.broken_links
    refute_empty manager.all_broken_links
    refute_empty manager.broken_link_map

    manager = LinkManager.new :link
    manager.append_broken_link doc, link, map: false

    refute_empty manager.broken_links
    refute_empty manager.all_broken_links
    assert_empty manager.broken_link_map
  end

  def test_remove_broken_link
    doc = Wgit::Document.new 'http://example.com'.to_url
    link = '/about.html'.to_url

    manager = LinkManager.new :page
    manager.append_broken_link doc, link
    manager.remove_broken_link link

    assert_empty manager.broken_links
    assert_empty manager.all_broken_links
    refute_empty manager.all_intact_links

    manager = LinkManager.new :page
    manager.append_broken_link doc, link
    manager.append_broken_link doc, '/contact.html'.to_url
    manager.remove_broken_link link

    assert_equal 1, manager.broken_links.size
    assert_equal 1, manager.all_broken_links.size
    assert_equal 1, manager.all_intact_links.size

    manager = LinkManager.new :link
    manager.append_broken_link doc, link
    manager.remove_broken_link link

    assert_empty manager.broken_links
    assert_empty manager.all_broken_links
    refute_empty manager.all_intact_links
  end

  def test_append_ignored_link
    doc = Wgit::Document.new 'http://example.com'.to_url
    link = 'mailto://me@gmail.com'.to_url
    manager = LinkManager.new :page
    manager.append_ignored_link doc.url, link

    refute_empty manager.ignored_links
    refute_empty manager.all_ignored_links
  end

  def test_append_intact_link
    link = 'mailto://me@gmail.com'.to_url
    manager = LinkManager.new :page
    manager.append_intact_link link

    refute_empty manager.all_intact_links
  end

  def test_sort
    doc  = Wgit::Document.new 'http://example.com'.to_url
    doc2 = Wgit::Document.new 'http://fedex.com'.to_url

    manager = LinkManager.new :page
    manager.append_broken_link  doc2,    '/contact'.to_url
    manager.append_broken_link  doc,     '/basketball'.to_url
    manager.append_broken_link  doc,     '/about'.to_url
    manager.append_broken_link  doc,     '/about'.to_url
    manager.append_ignored_link doc.url, 'mailto:brett@gmail.com'.to_url
    manager.append_ignored_link doc.url, 'mailto:alison@gmail.com'.to_url
    manager.append_ignored_link doc.url, 'mailto:alison@gmail.com'.to_url
    manager.sort

    assert_equal({
      'http://example.com' => %w[/about /basketball],
      'http://fedex.com'   => %w[/contact]
    }, manager.broken_links)
    assert_equal({
      'http://example.com' => %w[mailto:alison@gmail.com mailto:brett@gmail.com]
    }, manager.ignored_links)
  end

  def test_tally
    url = 'http://example.com'.to_url
    doc = Wgit::Document.new url

    manager = LinkManager.new :page
    manager.append_broken_link  doc, '/basketball'.to_url
    manager.append_ignored_link doc.url, 'mailto:brett@gmail.com'.to_url
    manager.append_intact_link 'mailto:brett@gmail.com'.to_url
    manager.tally url: url.to_s, pages_crawled: [url.to_s], start: Time.now - 10
    stats = manager.crawl_stats

    assert_equal url.to_s, stats[:url]
    assert_equal [url.to_s], stats[:pages_crawled]
    assert_equal 1, stats[:num_pages]
    assert_equal 3, stats[:num_links]
    assert_equal 1, stats[:num_broken_links]
    assert_equal 1, stats[:num_intact_links]
    assert_equal 1, stats[:num_ignored_links]
    assert stats[:duration] > 10
  end
end
