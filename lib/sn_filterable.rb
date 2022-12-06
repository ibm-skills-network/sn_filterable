# frozen_string_literal: true

require_relative "sn_filterable/version"
require_relative "sn_filterable/base_components/button_component"
require_relative "sn_filterable/category_component"
require_relative "sn_filterable/chips_component"
require_relative "sn_filterable/filter_button_component"
require_relative "sn_filterable/filter_category_component"
require_relative "sn_filterable/main_component"
require_relative "sn_filterable/search_component"
require_relative "sn_filterable/filterable"
require_relative "models/filtered"
require "active_support"
require "pg_search"

module SnFilterable
  include Filterable
end
