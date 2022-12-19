# frozen_string_literal: true

require_relative "sn_filterable/version"
require_relative "sn_filterable/railtie"
require_relative "sn_filterable/filterable"
require_relative "models/filtered"
require "sn_filterable/engine"
require "view_component"
require "kaminari"

module SnFilterable
  include SnFilterable::Filterable

  def self.load_js
    File.read(File.join(Gem.loaded_specs["sn_filterable"].full_gem_path, "app", "assets", "javascripts", "sn_filtering.js"))
  end

  # View helper for [Filtered].
  #
  # Defaults the URL of [Filtered] calls to use `url_for`.
  #
  # @see Filtered
  module FilteredHelper
    # Helper function of [Filtered#set_filter_url]
    #
    # @param [Filtered] filtered_instance
    # @param [String] filter_key
    # @param [String] value
    # @return [String]
    def set_filter_url(filtered_instance, filter_key, value, url: url_for)
      filtered_instance.set_filter_url(url, filter_key, value)
    end

    # Helper function of [Filtered#add_filter_url]
    #
    # @param [Filtered] filtered_instance
    # @param [String] filter_key
    # @param [String] value
    # @return [String]
    def add_filter_url(filtered_instance, filter_key, value, url: url_for)
      filtered_instance.add_filter_url(url, filter_key, value)
    end

    # Helper function of [Filtered#remove_filter_url]
    #
    # @param [Filtered] filtered_instance
    # @param [String] filter_key
    # @return [String]
    def remove_filter_url(filtered_instance, filter_key, url: url_for)
      filtered_instance.remove_filter_url(url, filter_key)
    end

    # Helper function of [Filtered#remove_sub_filter_url]
    #
    # @param [Filtered] filtered_instance
    # @param [String] filter_key
    # @param [String] filter_value
    # @return [String]
    def remove_sub_filter_url(filtered_instance, filter_key, filter_value, url: url_for)
      filtered_instance.remove_sub_filter_url(url, filter_key, filter_value)
    end

    # Helper function of [Filtered#clear_filter_url]
    #
    # @param [Filtered] filtered_instance
    # @return [String]
    def clear_filter_url(filtered_instance, url: url_for)
      filtered_instance.clear_filter_url(url)
    end

    # Helper function of [Filtered#clear_sort_url]
    #
    # @param [Filtered] filtered_instance
    # @return [String]
    def clear_sort_url(filtered_instance, url: url_for)
      filtered_instance.clear_sort_url(url)
    end

    # Helper function of [Filtered#clear_all_url]
    #
    # @param [Filtered] filtered_instance
    # @return [String]
    def clear_all_url(filtered_instance, url: url_for)
      filtered_instance.clear_all_url(url)
    end

    # Helper function of [Filtered#sort_url]
    #
    # @param [Filtered] filtered_instance
    # @param [String] sort_key
    # @param [Symbol, nil] order
    # @return [String]
    def sort_url(filtered_instance, sort_key, order: nil, url: url_for, &block)
      filtered_instance.sort_url(url, sort_key, order, &block)
    end

    # Creates an anchor element using `sort_url` and the block.
    # Additionally appends a suffix containing a triangle symbol
    # representing the direction of the sort
    # if we are currently sorting the items of [Filtered] using the `sort_key`.
    #
    # @param [Filtered] filtered_instance
    # @param [String] sort_key The sorting key to toggle
    # @param [Boolean] in_filterable_component If true, will add filterable component Alpine scripts
    def table_header_sort_link(filtered_instance, sort_key, scope: nil, html_options: nil, url: url_for, in_filterable_component: true, &block)
      url, state = filtered_instance.sort_url(url, sort_key, scope: scope)

      link_html_options = in_filterable_component ? { "@click": "filtersLoading = true", "class": "whitespace-nowrap" } : {}
      link_html_options = link_html_options.merge(html_options) if html_options.present?

      suffix = sanitize case state
                        when :asc
                          "&nbsp;&#9650;"
                        when :desc
                          "&nbsp;&#9660;"
                        else
                          ""
              end

      link_to(capture(&block) + suffix, url, link_html_options)
    end

    # Creates hidden inputs elements representing the current filter / sort values.
    # Useful for forms when we want to retain the user's current filtering parameters.
    #
    # When used on a form, this should be rendered first to avoid conflicts with other form inputs
    # defined. Duplicate input name's may exist but can be ignored as the last duplicate parameter occurrence
    # takes precedence.
    #
    # @param [Filtered] filtered_instance
    def filtered_form_inputs(filtered_instance)
      inputs = sanitize("")

      filtered_instance.queries.each do |key, value|
        case value
        when String
          inputs << content_tag(:input, "", type: :hidden, name: key, value: value)
        when Hash
          value.each do |subitem|
            inputs << content_tag(:input, "", type: :hidden, name: "#{key}[#{subitem[0]}]", value: subitem[1])
          end
        end
      end

      inputs
    end

    # Creates a form tag for filtered instances. See [FilteredFormBuilder] for
    # the helper methods
    #
    # @param [Filtered] filtered_instance
    # @see FilteredFormBuilder
    def filtered_form_with(filtered_instance, options = {}, &block)
      options[:method] = :get
      options[:builder] = FilteredFormBuilder
      options[:filtered] = filtered_instance

      form_with options, &block
    end

    # Renders a Tailwind paginated pagination section for a filtered instance.
    # Uses kaminari's paginate
    #
    # @param [Filtered] filtered_instance
    def filtered_paginate(filtered_instance)
      paginate filtered_instance.items, filtered: filtered_instance
    end
  end
end

Kaminari.configure do |config|
  config.default_per_page = 10
  config.max_per_page = 50
  config.window = 1
  config.outer_window = 1
  # config.left = 0
  # config.right = 0
  # config.page_method_name = :page
  # config.param_name = :page
  # config.max_pages = nil
  # config.params_on_first_page = false
end
