module SnFilterable
  require "view_component"
  # Renders the filtering interface
  #
  # ## Filters' info
  # An array of hashes in the following Hash format:
  #  - multi: [Boolean]; Determines if this filter supports multiple simultaneous subfilters. If true, the filter must be declared in the [Filterable]'s [ARRAY_FILTER_SCOPES]
  #  - title: [String]; The title to display on the filtering interface
  #  - filter_name: [String]; The filter's parameter name, see [Filterable]'s documentation
  #  - filters: [Array<Hash>]; An array of the available preset sub filters
  #    - name: [String]; The name of the sub filter to display in the interface
  #    - value: [String]; The value of the sub filter
  class MainComponent < ViewComponent::Base
    include Turbo::FramesHelper
    include Turbo::StreamsHelper
    include Heroicon::Engine.helpers

    renders_one :search

    # @param [String] frame_id The unique turbo frame ID
    # @param [Filtered] filtered The filtered instance
    # @param [Array<Hash>] filters An array of the filters' info (see [Filterable::MainComponent]'s documentation)
    # @param [String, nil] url Optional, the base URL of where the filters are displayed
    # @param [String, nil] search_filter_name Optional, enable's and set's the search filter, specified by the filter's parameter name
    # @param [Boolean] show_sidebar If true, will show the sidebar with the filters.
    # @param [Boolean] update_url_on_submit If true, will update the URL in the user's browser on form submission.
    # @param [Hash] extra_params Optional, allows for custom form values to be supplied. Useful if you need to retain non-filterable query params
    def initialize(frame_id:, filtered:, filters:, url: nil, search_filter_name: nil, show_sidebar: true, update_url_on_submit: true, extra_params: {})
      @frame_id = frame_id
      @filtered = filtered
      @filters = filters
      @url = url
      @search_filter_name = search_filter_name
      @show_sidebar = show_sidebar
      @update_url_on_submit = update_url_on_submit
      @extra_params = extra_params
      @filtered.extra_params = extra_params if extra_params.present?
    end

    def search_field
      SnFilterable::SearchComponent.new(filtered: @filtered, filter_name: @search_filter_name)
    end
  end
end
