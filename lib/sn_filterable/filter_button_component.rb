module Filterable
  # Handles rendering of the `View filters` button for mobile layouts
  class FilterButtonComponent < ViewComponent::Base
    # @param [Filtered] filtered The filtered instance
    # @param [Array<Hash>] filters An array of the filters' info
    def initialize(filtered:, filters:) # rubocop:disable Lint/MissingSuper
      @filtered = filtered
      @filters = filters
      @count = active_filter_count
    end

    private

    # Generates the count for the button suffix
    #
    # @return [String] a string of format: ` (COUNT)` or nil if no filters applied
    def active_filter_count
      count = 0

      @filtered.queries["filter"].each do |key, value|
        count += (value.is_a?(Array) ? value.length : 1) if @filters.any? { |x| x[:filter_name] == key }
      end

      return nil if count.zero?

      "\xA0(#{count})"
    end
  end
end
