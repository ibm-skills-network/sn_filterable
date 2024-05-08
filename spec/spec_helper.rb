# frozen_string_literal: true

require "rails"
require "rails/all"
require "with_model"
require "sn_filterable"
require "factory_bot"
require "faker"
require "kaminari"
require_relative "dummy/app/models/dummy_model"

ActiveRecord::Base.establish_connection(
  ENV["DATABASE_URL"] || "postgresql://postgres:password@localhost:5432/sn_filterable_test?schema=public&connection_limit=5"
)

FactoryBot.reload

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.extend WithModel
end
