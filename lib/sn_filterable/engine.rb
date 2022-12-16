require "rails/engine"
require "view_component/engine"

module SnFilterable
  class Engine < Rails::Engine
    config.autoload_paths = %W[
      #{root}/app/components
      #{root}/app/javascripts
    ]
  end
end
