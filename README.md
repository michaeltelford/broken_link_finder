# Broken Link Finder

Does what it says on the tin; Finds a website's broken links.

Simply point it at a website and it will crawl all of its webpages searching for and identifing any broken links. You will then be presented with a nice concise summary of the broken links found.

## How It Works

Any HTML page element with a `href` or `src` attribute is considered a link. For each link on a given page, any of the following conditions constitutes that the link is broken:

- A response status code of `404 Not Found` is returned.
- An empty HTML response body is returned.
- The HTML response body doesn't contain an element ID matching that of the link's anchor e.g. `http://server.com#about` must contain an element with `id="about"` or the link is considered broken.
- The link redirects more than 5 times consecutively.

**Note**: Not all link types are supported.

In a nutshell, only HTTP(S) based links can be successfully verified by `broken_link_finder`. As a result some links on a page might be (recorded and) ignored. You should verify these links yourself manually. Examples of unsupported link types include `tel:*`, `mailto:*`, `ftp://*` etc.

See the [usage](#Usage) section below on how to check which links have been ignored during a crawl.

With that said, the usual array of HTTP URL features are supported including anchors/fragments, query strings and IRI's (non ASCII based URL's).

## Made Possible By

`broken_link_finder` relies heavily on the `wgit` Ruby gem by the same author. See its [repository](https://github.com/michaeltelford/wgit) for more details.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'broken_link_finder'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install broken_link_finder

Finally, verify the installation with:

    $ broken_link_finder version

## Usage

You can check for broken links via the library or executable.

### Executable

Installing this gem installs the `broken_link_finder` executable into your `$PATH`. The executable allows you to find broken links from your command line. For example:

    $ broken_link_finder crawl http://txti.es

Adding the `-r` flag would crawl the entire `txti.es` site, not just its index page.

See the [output](#Output) section below for an example of a site with broken links.

You can peruse all of the available executable flags with:

    $ broken_link_finder help crawl

### Library

Below is a simple script which crawls a website and outputs its broken links to `STDOUT`:

> main.rb

```ruby
require 'broken_link_finder'

finder = BrokenLinkFinder.new
finder.crawl_site 'http://txti.es'    # Or use Finder#crawl_page for a single webpage.
finder.pretty_print_link_report       # Or use Finder#broken_links and Finder#ignored_links
                                      # for direct access to the link Hashes.
```

Then execute the script with:

    $ ruby main.rb

See the full source code documentation [here](https://www.rubydoc.info/gems/broken_link_finder).

## Output

If broken links are found then the output will look something like:

```text
Found 6 broken link(s) across 2 page(s):

The following broken links were found on 'http://txti.es/about':
http://twitter.com/thebarrytone
http://twitter.com/nwbld
http://twitter.com/txties
https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=84L4BDS86FBUU

The following broken links were found on 'http://txti.es/how':
http://en.wikipedia.org/wiki/Markdown
http://imgur.com

Ignored 3 unsupported link(s) across 2 page(s), which you should check manually:

The following links were ignored on http://txti.es:
tel:+13174562564
mailto:big.jim@jmail.com

The following links were ignored on http://txti.es/contact:
ftp://server.com
```

## Contributing

Bug reports and feature requests are welcome on [GitHub](https://github.com/michaeltelford/broken-link-finder). Just raise an issue.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new gem version:
- Update the version number in `version.rb` and add the new version to the `CHANGELOG`
- Run `bundle install`
- Run `bundle exec rake test` ensuring all tests pass
- Run `bundle exec rake compile` ensuring no warnings
- Run `bundle exec rake release[origin]`
