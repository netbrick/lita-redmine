Gem::Specification.new do |spec|
  spec.name          = "lita-redmine2"
  spec.version       = "0.1.0"
  spec.authors       = ["Jindrich Skupa / David Herman"]
  spec.email         = ["dev@netbrick.eu"]
  spec.description   = "Lita handlers for Redmine."
  spec.summary       = "Lita handlers for Redmine issue management."
  spec.homepage      = "https://github.com/netbrick/lita-redmine2"
  spec.license       = "MIT"
  spec.metadata      = { "lita_plugin_type" => "handler" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 4.3"
  spec.add_runtime_dependency "resource_kit"
  spec.add_runtime_dependency "json"
  spec.add_runtime_dependency "crypt"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rspec", ">= 3.0.0"
end
