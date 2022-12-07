# frozen_string_literal: true

require_relative "lib/sn_filterable/version"

Gem::Specification.new do |spec|
  spec.name = "sn_filterable"
  spec.version = SnFilterable::VERSION
  spec.authors = ["Chase McDougall"]
  spec.email = ["chasemcdougall@hotmail.com"]

  spec.summary = "Skills Network - Item filterting component"
  spec.description = "This gem adds a ViewComponent powered filtering component for searching and filtering your PostgreSQL data."
  spec.homepage = "https://github.com/ibm-skills-network/sn_filterable"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ibm-skills-network/sn_filterable"
  spec.metadata["changelog_uri"] = "https://github.com/ibm-skills-network/sn_filterable/releases"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  # spec.files = [
  #   "lib/sn_filterable.rb",
  #   "lib/sn_filterable/filterable.rb"
  # ]

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "heroicon" # TODO: Convert to inline SVG to avoid additional gem dependency
  spec.add_dependency "kaminari"
  spec.add_dependency "pg"
  spec.add_dependency "pg_search"
  spec.add_dependency "view_component"
  spec.add_dependency "turbo-rails"

  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "faker"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-github"
  spec.add_development_dependency "rubocop-rails"
  spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency "with_model"
  # spec.add_development_dependency "rails"
  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
