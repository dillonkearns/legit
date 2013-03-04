require File.expand_path("../lib/legit/version", __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Dillon Kearns"]
  gem.email         = ["dillon@dillonkearns.com"]
  gem.description   = "A collection of scripts for common git tasks to simplify and improve workflow."
  gem.summary       = gem.description
  gem.homepage      = "https://github.com/dillonkearns/legit"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "legit"
  gem.require_paths = ["lib"]
  gem.version       = Legit::VERSION

  gem.required_ruby_version = ">=1.8.7"

  gem.add_development_dependency "rake", "~> 10.0.3"
  gem.add_development_dependency "minitest", "~> 4.6.2"
  gem.add_development_dependency "minitest-reporters"
  gem.add_development_dependency "mocha", "~> 0.13.2"
  gem.add_development_dependency "guard-minitest"
  gem.add_development_dependency "growl"
  gem.add_development_dependency "rb-fsevent"

  gem.add_runtime_dependency     "thor", "~> 0.17.0"
  gem.add_runtime_dependency     "rugged", "0.17.0.b7"    # need version 0.17 for a bug accessing Rugged::Repo.config in 0.16
end
