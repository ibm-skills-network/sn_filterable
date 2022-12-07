module SnFilterable
    class Railtie < ::Rails::Railtie
      initializer "sn-filterable.load_components" do
        ActiveSupport.on_load(:action_view) do
          require_relative "main_component"
        end
      end
    #   initializer "sn-filterable.view_helpers" do |app|
    #     ActiveSupport.on_load(:action_view) do
    #       include TurboScroll::ViewHelpers
    #     end
    #     app.config.i18n.load_path += Dir[File.expand_path(File.join(File.dirname(__FILE__), '../locales', '*.yml')).to_s]
    #   end
    end
end