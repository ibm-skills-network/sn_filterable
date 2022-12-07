module SnFilterable
  # Component for a filter's category for the filters sidebar
  class FilterCategoryComponent < ViewComponent::Base
    include HeroiconHelper
    include FilteredHelper

    # @param [Filtered] filtered The filtered instance
    # @param [Hash] filters The filter's info
    def initialize(filtered:, filter:)
      @filtered = filtered
      @filter = filter
    end

    # Returns if this sub filter should be checked, denoting that the filter is active
    #
    # @param [String] sub_filter The sub filter's info
    # @return [Boolean] True if the filter should be checked
    def sub_filter_checked?(sub_filter)
      filter_query_value = @filtered.queries.dig("filter", @filter[:filter_name])

      return false if filter_query_value.blank?

      if filter_query_value.is_a?(Array)
        filter_query_value.include?((sub_filter[:value]).to_s)
      else
        filter_query_value == (sub_filter[:value]).to_s
      end
    end
  end
end
