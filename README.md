# Broken Link Finder

Does what it says on the tin - finds a website's broken links.

Simply point it at a website and it will crawl all of its webpages searching for and identifing broken links. You will then be presented with a concise summary of any broken links found.

Broken Link Finder is multi-threaded and uses `libcurl` under the hood, it's fast!

## How It Works

Any HTML element within `<body>` with a `href` or `src` attribute is considered a link (this is [configurable](#Link-Extraction) however).

For each link on a given page, any of the following conditions constitutes that the link is broken:

- An empty HTML response body is returned.
- A response status code of `404 Not Found` is returned.
- The HTML response body doesn't contain an element ID matching that of the link's fragment e.g. `http://server.com#about` must contain an element with `id="about"` or the link is considered broken.
- The link redirects more than 5 times consecutively.

**Note**: Not all link types are supported.

In a nutshell, only HTTP(S) based links can be successfully verified by `broken_link_finder`. As a result some links on a page might be (recorded and) ignored. You should verify these links yourself manually. Examples of unsupported link types include `tel:*`, `mailto:*`, `ftp://*` etc.

See the [usage](#Usage) section below on how to check which links have been ignored during a crawl.

With that said, the usual array of HTTP URL features are supported including anchors/fragments, query strings and IRI's (non ASCII based URL's).

## Made Possible By

`broken_link_finder` relies heavily on the `wgit` Ruby gem by the same author. See its [repository](https://github.com/michaeltelford/wgit) for more details.

## Installation

Only MRI Ruby is tested and supported, but `broken_link_finder` may work with other Ruby implementations.

Currently, the required MRI Ruby version is:

`ruby '>= 2.6', '< 4'`

### Using Bundler

    $ bundle add broken_link_finder

### Using RubyGems

    $ gem install broken_link_finder

### Verify

    $ broken_link_finder version

## Usage

You can check for broken links via the executable or library.

### Executable

Installing this gem installs the `broken_link_finder` executable into your `$PATH`. The executable allows you to find broken links from your command line. For example:

    $ broken_link_finder crawl http://txti.es

Adding the `--recursive` flag would crawl the entire `txti.es` site, not just its index page.

See the [output](#Output) section below for an example of a site with broken links.

You can peruse all of the available executable flags with:

    $ broken_link_finder help crawl

### Library

Below is a simple script which crawls a website and outputs its broken links to `STDOUT`:

> main.rb

```ruby
require 'broken_link_finder'

finder = BrokenLinkFinder.new
finder.crawl_site 'http://txti.es' # Or use Finder#crawl_page for a single webpage.
finder.report                      # Or use Finder#broken_links and Finder#ignored_links
                                   # for direct access to the link Hashes.
```

Then execute the script with:

    $ ruby main.rb

See the full source code documentation [here](https://www.rubydoc.info/gems/broken_link_finder).

## Output

If broken links are found then the output will look something like:

```text
Crawled http://txti.es
7 page(s) containing 32 unique link(s) in 6.82 seconds

Found 6 unique broken link(s) across 2 page(s):

The following broken links were found on 'http://txti.es/about':
http://twitter.com/thebarrytone
/doesntexist
http://twitter.com/nwbld
twitter.com/txties

The following broken links were found on 'http://txti.es/how':
http://en.wikipedia.org/wiki/Markdown
http://imgur.com

Ignored 3 unique unsupported link(s) across 2 page(s), which you should check manually:

The following links were ignored on 'http://txti.es':
tel:+13174562564
mailto:big.jim@jmail.com

The following links were ignored on 'http://txti.es/contact':
ftp://server.com
```

You can provide the `--html` flag if you'd prefer a HTML based report.

## Link Extraction

You can customise the XPath used to extract links from each crawled page. This can be done via the executable or library.

### Executable

Add the `--xpath` (or `-x`) flag to the crawl command e.g.

    $ broken_link_finder crawl http://txti.es -x //img/@src

### Library

Set the desired XPath using the accessor methods provided:

> main.rb

```ruby
require 'broken_link_finder'

# Set your desired xpath before crawling...
BrokenLinkFinder::link_xpath = '//img/@src'

# Now crawl as normal and only your custom targeted links will be checked.
BrokenLinkFinder.new.crawl_page 'http://txti.es'

# Go back to using the default provided xpath as needed.
BrokenLinkFinder::link_xpath = BrokenLinkFinder::DEFAULT_LINK_XPATH
```

## Contributing

Bug reports and feature requests are welcome on [GitHub](https://github.com/michaeltelford/broken-link-finder). Just raise an issue.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new gem version:
- Update the deps in the `*.gemspec`, if necessary.
- Update the version number in `version.rb` and add the new version to the `CHANGELOG`.
- Run `bundle install`.
- Run `bundle exec rake test` ensuring all tests pass.
- Run `bundle exec rake compile` ensuring no warnings.
- Run `bundle exec rake install && rbenv rehash`.
- Manually test the executable.
- Run `bundle exec rake release[origin]`.
