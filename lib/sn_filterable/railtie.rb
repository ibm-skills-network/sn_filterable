module SnFilterable
  class Railtie < ::Rails::Railtie
    initializer "sn-filterable.load_components" do
      ActiveSupport.on_load(:action_view) do
        require_relative "main_component"
        require_relative "search_component"
        require_relative "category_component"
        require_relative "filter_category_component"
        require_relative "filter_button_component"
        require_relative "chips_component"
        require_relative "base_components/button_component"
      end
    end
    initializer "sn-filterable.view_helpers" do |app|
      ActiveSupport.on_load(:action_view) do
        # include Heroicon::Engine.helpers
        include SnFilterable::FilteredHelper
      end
      # app.config.i18n.load_path += Dir[File.expand_path(File.join(File.dirname(__FILE__), '../locales', '*.yml')).to_s]
    end
  end
end
