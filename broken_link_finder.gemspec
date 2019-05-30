# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'broken_link_finder/version'

Gem::Specification.new do |spec|
  spec.name          = "broken_link_finder"
  spec.version       = BrokenLinkFinder::VERSION
  spec.authors       = ["Michael Telford"]
  spec.email         = ["michael.telford@live.com"]

  spec.summary       = "Finds a websites broken links and reports back to you with a summary."
  spec.description   = "Finds a websites broken links using the 'wgit' gem and reports back to you with a summary."
  spec.homepage      = "https://github.com/michaeltelford/broken-link-finder"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  # spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "pry", "~> 0.12"
  spec.add_development_dependency "byebug", "~> 11.0"

  spec.add_runtime_dependency "wgit"
end
