require "rails/engine"
require "view_component/engine"

module SnFilterable
  class Engine < Rails::Engine
    config.autoload_paths = %W[
      #{root}/app/components
    ]

    initializer "sn_filterable.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.precompile += %w[sn_filtering.js]
      end
    end
  end
end
