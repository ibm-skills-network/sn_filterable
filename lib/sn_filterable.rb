# frozen_string_literal: true

# require_relative "sn_filterable/version"
# require_relative "sn_filterable/base_components/button_component"
# require_relative "sn_filterable/category_component"
# require_relative "sn_filterable/chips_component"
# require_relative "sn_filterable/filter_button_component"
# require_relative "sn_filterable/filter_category_component"
# require_relative "sn_filterable/main_component"
# require_relative "sn_filterable/search_component"
require_relative "sn_filterable/filterable"
require_relative "models/filtered"
# require "active_support"
# require "pg_search"
require "kaminari"

module SnFilterable
  include SnFilterable::Filterable
end

Kaminari.configure do |config|
  config.default_per_page = 10
  config.max_per_page = 50
  config.window = 1
  config.outer_window = 1
  # config.left = 0
  # config.right = 0
  # config.page_method_name = :page
  # config.param_name = :page
  # config.max_pages = nil
  # config.params_on_first_page = false
end
