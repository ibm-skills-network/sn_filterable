# frozen_string_literal: true

# Helper class that provides access to the filtered items and generation
# of sort/filter URLs for the items.
#
# Should not be initialized directly, models should implement [Filterable] instead.
#
# @see Filterable
class Filtered
  attr_accessor :items, :queries

  # @param [Class] model_class The class of the ActiveRecord::Base subclass
  # @param [ActiveRecord::Relation] items The items sorted and filtered by [Filterable]
  # @param [Hash] queries A hash of the sorting / filtering parameters
  # @param [Symbol] sort_name The current sorting name
  # @param [Boolean] sort_reversed True when the current sorting order is reversed
  def initialize(model_class, items, queries, sort_name, sort_reversed)
    @model_class = model_class
    @items = items
    @queries = queries
    @sort_name = sort_name
    @sort_reversed = sort_reversed
  end

  # Returns if any filters are active
  # @return [Boolean] True if at least one filter is active
  def active_filters?
    @queries["filter"].present?
  end

  # Sets one filter to the URL.
  #
  # @param [String] url The URL to apply the filter to
  # @param [String] key The filter's key
  # @param [String] value The value to apply using the filter
  # @return [String] the modified URL with the filter applied
  def set_filter_url(url, key, value)
    modify_url_queries(url) do |queries|
      queries["filter"] = { key => value }
    end
  end

  # Adds a filter to the URL.
  #
  # @param [String] url The URL to add the filter to
  # @param [String] key The filter's key
  # @param [String] value The value to apply using the filter
  # @return [String] the modified URL with the filter added
  def add_filter_url(url, key, value)
    modify_url_queries(url) do |queries|
      queries["filter"][key] = value
    end
  end

  # Removes a filter from the URL.
  #
  # @param [String] url The URL to remove the filter from
  # @param [String] key The filter's key to remove
  # @return [String] the modified URL with the filter removed
  def remove_filter_url(url, key)
    modify_url_queries(url) do |queries|
      queries["filter"].delete(key)
    end.chomp("?")
  end

  # Removes a sub filter from the URL.
  #
  # @param [String] url The URL to remove the filter from
  # @param [String] key The filter's key to match
  # @param [String] value The filter's value to remove
  # @return [String] the modified URL with the filter removed
  def remove_sub_filter_url(url, key, value)
    modify_url_queries(url) do |queries|
      queries["filter"][key].delete(value.to_s) if queries["filter"][key].is_a?(Array)
    end.chomp("?")
  end

  # Clears all filters from the URL.
  #
  # @param [String] url The url to remove the filter from
  # @return [String] the modified URL with all filters removed
  def clear_filter_url(url)
    clear_url(url, true, false)
  end

  # Clears sorting from the URL.
  #
  # @param [String] url The url to remove the sorting parameters from
  # @return [String] the modified URL with no defined sort
  def clear_sort_url(url)
    clear_url(url, false, true)
  end

  # Clears all filters and sorting from the URL.
  #
  # @param [String] url The url to remove the sorting and filtering from
  # @return [String] the modified URL with all filters and sorting removed
  def clear_all_url(url)
    clear_url(url, true, true)
  end

  # Generates a URL used in table headers for column sorting.
  #
  # Calls and returns `block`, providing the following parameters in the following order:
  #  - url: [String] The URL for the column sorting which links to the *next* sorting state
  #  - state: [nil, Symbol] The *current* sorting state of the provided key. Provides the key's sorting order as a symbol, either `:asc`, or `:desc` when active. Returns `nil`, this sorting key is not active.
  #
  # When the sorting key provided is active for this [Filtered] instance, this method will
  # return a URL with the order reversed.
  #
  # @param [String] url The url to apply the sort parameters on
  # @param [String] key The sorting key to toggle
  # @param [Symbol, nil] order Optional, sets the sorting order. If set to nil, will toggle the order instead.
  # @return the value returned from the block. If no block is given, [Array(String, Symbol | nil)] is returned, which contains the URL and state respectively
  def sort_url(url, key, order = nil, scope: nil)
    state = nil
    url = modify_url_queries(url) do |queries|
      queries["sort"] = key

      if @sort_name == key
        state = @sort_reversed ? :desc : :asc
        queries["order"] = @sort_reversed ? "asc" : "desc"
      else
        queries.delete("order")
      end

      queries["order"] = order.to_s unless order.nil?

      queries["scope"] = scope.to_s unless scope.nil?
    end

    return yield(url, state) if block_given?

    [url, state]
  end

  private

  # Clears parameters from the URL.
  #
  # @param [String] url The url to remove the filter from
  # @param [Boolean] clear_filter If true, will clear all filters from the URL
  # @param [Boolean] clear_sort If true, will clear the sort parameters from the URL
  # @return [String] the cleared URL
  def clear_url(url, clear_filter, clear_sort)
    modify_url_queries(url) do |queries|
      queries.delete("filter") if clear_filter

      if clear_sort
        queries.delete("sort")
        queries.delete("order")
      end
    end.chomp("?")
  end

  # Modifies a URL query parameters by calling `block`,
  # providing the mutable queries as the first parameter.
  #
  # @param url [String] The base URL
  # @return [String] the modified URL
  def modify_url_queries(url)
    uri = URI.parse(url)
    query = Rack::Utils.parse_nested_query(uri.query).deep_merge(@queries.deep_dup)

    yield(query) if block_given?

    uri.query = Rack::Utils.build_nested_query(query)

    uri.to_s
  end
end
