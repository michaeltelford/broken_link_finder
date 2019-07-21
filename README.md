# Broken Link Finder

Does what it says on the tin. Finds a website's broken links.

Simply point it at a website and it will crawl all of its webpages searching for and identifing any broken links. You will then be presented with a nice concise summary of the broken links found.

## How It Works

Any page element with a `href` or `src` attribute is considered a link. For each link on a given page, any of the following conditions (in order) constitutes that the link is broken:

1) A response status code of `404 Not Found` is returned.
2) An empty HTML response body is returned.
3) The HTML response body doesn't contain an element ID matching that of the link's anchor e.g. `http://server.com#about` must contain an element with an ID of `about` or the link is considered broken.

## Made Possible By

This repository utilises the awesome `wgit` Ruby gem. See its [repository](https://github.com/michaeltelford/wgit) for more details.

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

finder = BrokenLinkFinder::Finder.new
finder.crawl_site "http://txti.es" # Also, see Finder#crawl_page for a single webpage.
finder.pretty_print_broken_links # Also, see Finder#broken_links for a Hash of links.
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
