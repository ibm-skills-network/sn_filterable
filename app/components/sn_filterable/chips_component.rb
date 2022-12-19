module SnFilterable
  # Handles rendering of the chips for the filters
  class ChipsComponent < ViewComponent::Base
    include FilteredHelper

    # @param [Filtered] filtered The filtered instance
    # @param [Array<Hash>] filters An array of the filters' info
    # @param [String] url The base URL of where the filters are displayed
    def initialize(filtered:, filters:, url:)
      @filtered = filtered
      @filters = filters
      @url = url
      @known_filters = parsed_filters
    end

    private

    # Parses all the queries and builds a [Hash] array that contains info about each filter used
    def parsed_filters
      filters = []

      @filtered.queries["filter"].each do |filter_name, filter_value|
        filter = @filters.find { |x| x[:filter_name] == filter_name }
        next if filter.nil?

        if filter_value.is_a?(Array)
          filter_value.each do |sub_filter|
            value = parse_multi_filter(filter, sub_filter)

            filters.append(value) if value.present?
          end
        else
          value = parse_single_filter(filter, filter_value)

          filters.append(value) if value.present?
        end
      end

      filters
    end

    # Parses a value from filter that supports multiple values
    #
    # @param [Hash] filter The filter info
    # @param [String] sub_filter_value The sub filter's value
    # @return [Hash]
    def parse_multi_filter(filter, sub_filter_value)
      value = filter[:filters].find { |x| x[:value].to_s == sub_filter_value }

      return nil if value.blank?

      {
        multi: true,
        parent: filter[:filter_name],
        name: value[:name],
        value: sub_filter_value
      }
    end

    # Parses a filter that supports a single value
    #
    # @param [Hash] filter The filter info
    # @param [String] filter_value The filter's value
    # @return [Hash]
    def parse_single_filter(filter, filter_value)
      value = filter[:filters].find { |x| x[:value].to_s == filter_value }

      return nil if value.blank?

      {
        multi: false,
        parent: filter[:filter_name],
        name: value[:name],
        value: filter_value
      }
    end
  end
end
