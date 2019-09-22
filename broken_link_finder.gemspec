# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'broken_link_finder/version'

Gem::Specification.new do |spec|
  spec.name          = "broken_link_finder"
  spec.version       = BrokenLinkFinder::VERSION
  spec.author        = "Michael Telford"
  spec.email         = "michael.telford@live.com"

  spec.summary       = "Finds a website's broken links and reports back to you with a summary."
  spec.description   = "Finds a website's broken links using the 'wgit' gem and reports back to you with a summary."
  spec.homepage      = "https://github.com/michaeltelford/broken-link-finder"
  spec.license       = "MIT"
  spec.metadata      = {
    "source_code_uri" => "https://github.com/michaeltelford/broken-link-finder",
  }

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = ["broken_link_finder"]
  spec.require_paths = ["lib"]
  spec.post_install_message = "Added the executable 'broken_link_finder' to $PATH"

  spec.required_ruby_version = '~> 2.5'

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "pry", "~> 0.12"
  spec.add_development_dependency "byebug", "~> 11.0"
  spec.add_development_dependency "webmock", "~> 3.5"
  spec.add_development_dependency "httplog", "~> 1.3"
  spec.add_development_dependency "memory_profiler", "~> 0.9"

  spec.add_runtime_dependency "wgit", "0.2.0"
  spec.add_runtime_dependency "thread", "0.2"
  spec.add_runtime_dependency "thor", "0.20.3"
end
