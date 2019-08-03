# Broken Link Finder

Does what it says on the tin. Finds a website's broken links.

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

## Made Possible By

`broken_link_finder` relies heavily on the `wgit` Ruby gem. See its [repository](https://github.com/michaeltelford/wgit) for more details.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'broken_link_finder'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install broken_link_finder

## Usage

### Executable

Installing this gem installs the `broken_link_finder` executable into your `$PATH`. The executable allows you to find broken links from your command line. For example:

    $ broken_link_finder crawl http://txti.es

Adding the `-r` switch would crawl the entire txti.es site, not just it's index page.

See the [output](#Output) section below for an example of a site with broken links.

### Library

Below is a simple script which crawls a website and outputs it's broken links to `STDOUT`.

> main.rb

```ruby
require 'broken_link_finder'

finder = BrokenLinkFinder.new
finder.crawl_site "http://txti.es"    # Or use Finder#crawl_page for a single webpage.
finder.pretty_print_link_report      # Or use Finder#broken_links and Finder#ignored_links
                                      # for direct access to the link Hashes.
```

Then execute the script with:

    $ ruby main.rb

## Output

If broken links are found then the output will look something like:

```text
Below is a breakdown of the different pages and their broken links...

The following broken links exist in http://txti.es/about:
http://twitter.com/thebarrytone
http://twitter.com/nwbld
http://twitter.com/txties
https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=84L4BDS86FBUU

The following broken links exist in http://txti.es/how:
http://en.wikipedia.org/wiki/Markdown
http://imgur.com

Below is a breakdown of the non supported (ignored) links found, you should check these manually:

The following links were ignored on http://txti.es:
tel:+13174562564
mailto:big.jim@jmail.com

The following links were ignored on http://txti.es/contact:
ftp://server.com
```

## TODO

- Add logger functionality (especially useful in the console during development).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release[origin]`, which will create a git tag for the version, push git commits and tags, and push the `*.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/michaeltelford/broken-link-finder).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
