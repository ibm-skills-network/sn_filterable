# frozen_string_literal: true

require_relative "lib/sn_filterable/version"

Gem::Specification.new do |spec|
  spec.name = "sn_filterable"
  spec.version = SnFilterable::VERSION
  spec.authors = ["IBM Skills Network"]
  spec.email = ["Skills.Network@ibm.com"]

  spec.summary = "Skills Network - Item filtering component"
  spec.description = "This gem adds a ViewComponent powered filtering component for searching and filtering your PostgreSQL or MySQL data."
  spec.homepage = "https://github.com/ibm-skills-network/sn_filterable"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ibm-skills-network/sn_filterable"
  spec.metadata["changelog_uri"] = "https://github.com/ibm-skills-network/sn_filterable/releases"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir["{app,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "heroicon", "~> 1"
  spec.add_dependency "kaminari", "~> 1"
  spec.add_dependency "tailwindcss-rails", "~> 4"
  spec.add_dependency "turbo-rails", "~> 2"
  spec.add_dependency "view_component", "~> 3"

  spec.add_development_dependency "pg", "~> 1"
  spec.add_development_dependency "mysql2", "~> 0.5"
  spec.add_development_dependency "factory_bot_rails", "~> 6"
  spec.add_development_dependency "faker", "~> 3"
  spec.add_development_dependency "rake", "~> 13"
  spec.add_development_dependency "rspec-rails", "~> 6"
  spec.add_development_dependency "rubocop-performance", "~> 1"
  spec.add_development_dependency "rubocop-github", "~> 0"
  spec.add_development_dependency "rubocop-rails", "~> 2"
  spec.add_development_dependency "rubocop-rspec", "~> 2"
  spec.add_development_dependency "with_model", "~> 2"
  # spec.add_development_dependency "rails"
  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
