require_relative "filter_category_component"

module SnFilterable
  # Renders a category to be displayed in the filtering sidebar/popup.
  # Simple view component, logic to display filters should render a [:filter] (see [Filterable::FilterCategoryComponent])
  class CategoryComponent < ViewComponent::Base
    include Heroicon::Engine.helpers

    renders_one :filter, SnFilterable::FilterCategoryComponent

    # @param [String] title Optional, the title of the category, will default to the filter's title (if specified)
    # @param [Boolean] open Optional, determines if the category should be opened by default
    def initialize(title: nil, open: false)
      @title = title
      @open = open
    end
  end
end
