module Filterable
  # Renders the optional search bar
  class SearchComponent < ViewComponent::Base
    include HeroiconHelper

    # @param [Filtered] filtered The filtered instance
    # @param [String] filter_name The search filter's parameter name
    def initialize(filtered:, filter_name:)
      @filtered = filtered
      @filter_name = filter_name
    end
  end
end
