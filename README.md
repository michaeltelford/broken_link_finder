# Broken Link Finder

Does what it says on the tin. Finds a website's broken links. 

Simply point it at a website and it will crawl all of its webpages searching for and identifing any broken links. You will then be presented with a nice concise summary of the broken links found.

## Made Possible By

This repository utilises the awesome `wgit` Ruby gem. See its [repository](https://github.com/michaeltelford/wgit) for more details.

The only gotcha is that `wgit` doesn't currently follow redirects meaning they will appear as broken links in the results.

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

Below is a sample script which crawls a website and outputs its broken links to a file.

> main.rb

```ruby
require 'broken_link_finder'

finder = BrokenLinkFinder::Finder.new
finder.crawl_site "http://txti.es" # Also, see Finder#crawl_url for a single webpage.
finder.pretty_print_broken_links
```

Then execute the script with:

    $ ruby main.rb

The output should look something like:

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

- Create a `broken_link_finder` executable.
- Add logger functionality (especially useful in the console during development).
- Update the `wgit` gem as soon as redirects are implemented.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub [here](https://github.com/michaeltelford/broken-link-finder).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
