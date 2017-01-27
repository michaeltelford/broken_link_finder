# Broken Link Finder

Does what it says on the tin. Finds a websites broken links. 

Simply point it a website and it will crawl all its webpages searching for and identifing any broken links on those pages. You will then be presented with a nice concise summary of your sites broken links.

The only exception or gotcha is that the `wgit` doesn't currently follow redirects meaning they will appear as broken links in the results.  

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

```ruby
require 'broken_link_finder'

include BrokenLinkFinder

def main(url)
  # Removes the protocol prefix for the filename. 
  file_path = "/Users/<username>/Downloads/broken_links/#{url[7..-1]}.txt"

  finder = Finder.new url
  finder.crawl_site
  
  File.open file_path, "a+" do |f|
    finder.pretty_print_broken_links f
  end
end

urls = [
  "https://opensource.org",
]

urls.each { |url| main url }
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub [here](https://github.com/michaeltelford/broken-link-finder).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
