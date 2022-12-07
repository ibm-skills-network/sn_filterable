module SnFilterable
    class Railtie < ::Rails::Railtie
      initializer "sn-filterable.load_components" do
        ActiveSupport.on_load(:action_view) do
          require_relative "main_component"
        end
      end
    end
end
