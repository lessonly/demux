$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "demux/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "demux"
  spec.version     = Demux::VERSION
  spec.authors     = ["Ross Reinhardt"]
  spec.email       = ["rreinhardt9@gmail.com"]
  spec.homepage    = "https://github.com/rreinhardt9/demux"
  spec.summary     = "Configure your application to send signals to a constellation of other 'apps'"
  spec.description = "Configure your application to send signals to a constellation of other 'apps'"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/rreinhardt9/demux/CHANGELOG.md"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "jwt", ">= 1.5", "< 3"
  spec.add_dependency "rails", "< 7", ">= 5.1"

  spec.add_development_dependency "pg"
  spec.add_development_dependency "webmock"
end
