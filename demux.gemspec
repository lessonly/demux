$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "demux/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "demux"
  spec.version     = Demux::VERSION
  spec.authors     = ["Ross Reinhardt"]
  spec.email       = ["rreinhardt9@gmail.com"]
  spec.homepage    = ""
  spec.summary     = ""
  spec.description = ""
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "jwt", ">= 1.5", "< 3"
  spec.add_dependency "rails", "< 7", ">= 5.1"

  spec.add_development_dependency "pg"
  spec.add_development_dependency "webmock"
end
