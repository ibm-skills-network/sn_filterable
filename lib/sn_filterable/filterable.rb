# frozen_string_literal: true

# Concern to add sorting and filtering for ActiveRecord models.
#
# The following constants must to be implemented in the base class
# for filtering and sorting to work:
#
# `FILTER_SCOPE_MAPPINGS`: A [Hash] that maps a filter's parameter name to the filter's scope. The scope's proc should have a single argument for filtering. Multiple filters will be ANDed when building the full query.
#
# `ARRAY_FILTER_SCOPES`: An [Array] of filter parameter names that support having multiple values. If multiple filters of the same key are provided, the value's scope will be ORed when building the filter's query.
#
# `SORT_SCOPE_MAPPINGS`: A [Hash] that maps a sorting name to the sorting scope. If the scope is complex preventing automatic reversal, another scope with the suffix '_reversed' must be made.
#
# `DEFAULT_SORT`: Optional, sets the default sort of the items when no sorting parameter is set. Can be either a [String], which returns the sorting name or an [Array], where the first item is the sorting name and the second item is the sort direction (either `:asc` or `:desc`).
#
# @see Filtered

module SnFilterable
  module Filterable
    extend ActiveSupport::Concern

    class_methods do
      # Filters and sorts the model's items.
      #
      # @param [ActionController::Parameters] params The unfiltered parameters
      # @param [ActiveRecord::Relation] items Optional, the items to scope from the model
      # @param [String, Array, nil] default_sort Optional, similar to the `DEFAULT_SORT` constant, sets the default sort of items when no sorting parameter is set. Can be either a [String], which returns the sorting name or an [Array], where the first item is the sorting name and the second item is the sort direction (either `:asc` or `:desc`). Will take precedence over the `DEFAULT_SORT` constant.
      # @param [Boolean] pagination_enabled Optional, toggles pagination
      # @return [Filtered] the filtered and sorted items
      def filter(params:, items: where(nil), default_sort: nil, pagination_enabled: true)
        filter_params = filter_params(params)
        sort_params = sort_params(params)
        other_params = other_params(params, items)
        items, sort_name, reverse_order = perform_sort(items, sort_params, default_sort)
        items = perform_filter(items, filter_params)
        items = items.page(other_params[:page]).per(other_params[:per]) if pagination_enabled

        Filtered.new(self, items, generate_url_queries(filter_params, sort_params, other_params), sort_name, reverse_order)
      end

      private

      # Filters the items using the provided parameters. All filters' clauses are ANDed.
      #
      # @param [ActiveRecord::Relation] items
      # @param [ActionController::Parameters] params The filter parameters
      # @return [ActiveRecord::Relation] the filtered items
      def perform_filter(items, params)
        params[:filter].try(:each) do |key, value|
          filter_items = perform_single_filter(items, key, value)

          items = items.merge(filter_items) unless filter_items.nil?
        end

        items
      end

      # Builds the relation for a single filter.
      #
      # All filters are performed against `items.model.all` to build a generic relation against the table.
      # To be used with `#perform_filter` which will reduce the scope of the returned relation by ANDing.
      #
      # When an array of values is given, each value's clause is ORed.
      #
      # @param [ActiveRecord::Relation] items
      # @param [String] key The filtering key
      # @param [String, Array<String>] value The value(s) to sort
      # @return [ActiveRecord::Relation, nil] returns the relation or `nil` if a non-empty value was given
      def perform_single_filter(items, key, value)
        if value.present?
          return items.model.all.public_send(const_get(:FILTER_SCOPE_MAPPINGS)[key.to_sym], value) unless value.is_a?(Array)

          output_items = nil

          value.each do |x|
            next if x.blank?

            filter_items = items.model.all.public_send(const_get(:FILTER_SCOPE_MAPPINGS)[key.to_sym], x)
            output_items = output_items.nil? ? filter_items : output_items.or(filter_items)
          end

          return output_items
        end

        nil
      end

      # Sorts the items using the `sort` and `order` parameters. Will default to using
      # the default sort when the sorting parameters are not present.
      #
      # @param [ActiveRecord::Relation] items
      # @param [ActionController::Parameters] params The sort parameters
      # @param [String, Array, nil] default_sort
      # @return [Array(ActiveRecord::Relation, Symbol | nil, Boolean)] the sorted items, sorting name and sorting order
      def perform_sort(items, params, default_sort)
        sort_name = nil
        reverse_order = params[:order] == "desc"

        if params[:sort].present?
          sort_name = params[:sort]
        elsif default_sort.present? || const_defined?(:DEFAULT_SORT)
          default_sort ||= const_get(:DEFAULT_SORT) if const_defined?(:DEFAULT_SORT)

          sort_name, reverse_order = parse_default_sort(default_sort)
        end

        items = sort_items(items, sort_name, reverse_order, scope: params[:scope]) if sort_name.present?

        [items, sort_name, reverse_order]
      end

      # Parses the default sort.
      #
      # @param [String, Array, nil] default_sort
      # @return [Array(Symbol, Boolean)] the sorting scope and the sorting order
      def parse_default_sort(default_sort)
        sort_scope = nil
        reverse_order = false

        case default_sort
        when Array
          sort_scope = default_sort[0]
          reverse_order = default_sort[1] == :desc
        when String
          sort_scope = default_sort
        else
          raise TypeError, "Invalid type found for the default sort, expected either Array or Symbol, got #{default_sort.class}"
        end

        [sort_scope, reverse_order]
      end

      # Sorts the items using the sorting scope and reversing the sort if required.
      # Will prioitize using the explicit `_reversed` scope over reversing automatically.
      #
      # @param [ActiveRecord::Relation] items The items to sort
      # @param [String] sort_name The sorting name
      # @param [Boolean] reverse_order If true, will attempt to reverse the order of the sort
      # @return [ActiveRecord::Relation] the sorted items
      def sort_items(items, sort_name, reverse_order, scope: nil)
        sort_scope = const_get(:SORT_SCOPE_MAPPINGS)[sort_name.to_sym]
        reversed_sort_scope_sym = "#{sort_scope}_reversed".to_sym

        if reverse_order && methods.include?(reversed_sort_scope_sym)
          items.public_send(reversed_sort_scope_sym)
        else
          items = if scope.nil?
                    items.public_send(sort_scope)
                  else
                    items.public_send(sort_scope, scope.to_i)
                  end
          items = items.reverse_order if reverse_order

          items
        end
      end

      # Scopes the user parameters to only contain filtering parameters.
      #
      # @param [ActionController::Parameters] params
      # @return [ActionController::Parameters]
      def filter_params(params)
        return ActionController::Parameters.new.permit unless const_defined?(:FILTER_SCOPE_MAPPINGS)

        filters_with_array_support = const_defined?(:ARRAY_FILTER_SCOPES) ? const_get(:ARRAY_FILTER_SCOPES)&.map { |x| { x => [] } } : []

        params.permit(filter: const_get(:FILTER_SCOPE_MAPPINGS).keys.concat(filters_with_array_support))
      end

      # Scopes the user parameters to only contain sorting parameters.
      #
      # @param [ActionController::Parameters] params
      # @return [ActionController::Parameters]
      def sort_params(params)
        params = params.permit(:sort, :order, :scope)
        return ActionController::Parameters.new.permit unless sort_params_valid?(params)

        params
      end

      # Validates the sorting parameters.
      #
      # @param [ActionController::Parameters] params
      def sort_params_valid?(params)
        const_defined?(:SORT_SCOPE_MAPPINGS) &&
          params[:sort].present? && params[:sort].in?(const_get(:SORT_SCOPE_MAPPINGS).keys.map(&:to_s)) &&
          (params[:order].blank? || params[:order].in?(%w[asc desc]))
      end

      # Scopes the user parameters to contain only other parameters (pagination parameters, :page, :per)
      #
      # @param [ActionController::Parameters] params
      # @param [ActiveRecord::Relation] items The items to scope from the model, used to determine pagination max
      # @return [ActionController::Parameters]
      def other_params(params, items)
        params = params.permit(:page, :per)

        return ActionController::Parameters.new.permit unless other_params_valid?(params, items)

        params
      end

      # Validates the other parameters.
      #
      # @param [ActionController::Parameters] params
      # @param [ActiveRecord::Relation] items The items to scope from the model, used to determine pagination max
      def other_params_valid?(params, items)
        params[:per].blank? || params[:per].to_i.between?(1, items.max_per_page)
      end

      # Generates a valid hash of the sorting and filtering queries.
      #
      # @param [ActionController::Parameters] f_params The filter parameters
      # @param [ActionController::Parameters] s_params The sort parameters
      # @param [ActionController::Parameters] o_params The other parameters
      # @return [Hash] the valid URL queries
      def generate_url_queries(f_params, s_params, o_params)
        queries = { "filter" => {} }

        f_params["filter"].try(:each) { |k, v| queries["filter"][k] = v }

        queries["sort"] = s_params["sort"] if s_params["sort"].present?
        queries["order"] = s_params["order"] if s_params["order"].present?
        queries["page"] = o_params["page"] if o_params["page"].present?
        queries["per"] = o_params["per"] if o_params["per"].present?

        queries
      end
    end

    # Helper class for generating `WHERE` conditions
    class WhereHelper
      # Helper to find if a value exists in a string (case-insensitive)
      #
      # @param [String] column_key The column's key to search
      # @param [String] value The value to look for (case-insensitive)
      def self.contains(column_key, value)
        ["strpos(LOWER(#{column_key}), ?) > 0", value.downcase.strip]
      end
    end

    # Helper class for handling polymorphic associations
    class PolymorphicHelper
      # Helper to join the polymorphic associated tables.
      #
      # @param [ActiveRecord::Relation] relation The relation to apply the JOIN clause
      # @param [Symbol, String] polymorphic_association The name of the polymorphic association
      # @param [Array<Class>] models An array of the models that the polymorphic association applies to
      # @return [ActiveRecord::Relation]
      def self.joins(relation, polymorphic_association, models)
        table_name = ActiveRecord::Base.connection.quote_table_name(relation.table.name)
        polymorphic_association_id = ActiveRecord::Base.connection.quote_column_name("#{polymorphic_association}_id")
        polymorphic_association_type = ActiveRecord::Base.connection.quote_column_name("#{polymorphic_association}_type")

        models.each do |model|
          associated_table = ActiveRecord::Base.connection.quote_table_name(model.table_name)
          associated_type = model.name

          join_query = ActiveRecord::Base.sanitize_sql_array([
                                                              "LEFT OUTER JOIN #{associated_table} ON #{associated_table}.id = #{table_name}.#{polymorphic_association_id} AND #{table_name}.#{polymorphic_association_type} = ?",
                                                              associated_type
                                                            ])

          relation = relation.joins(join_query)
        end

        relation
      end

      # Coalesces the columns of a polymorphic association. Should be used in a relation that used the {#joins} helper.
      #
      # @param [Array<Class>] models An array of the models that the polymorphic association applies to
      # @param [String] column The mutual column that exists in the models
      # @return [String] the coalesce SQL function
      def self.coalesce(models, column)
        column = ActiveRecord::Base.connection.quote_column_name(column)

        sql_columns = []

        models.each do |model|
          associated_table = ActiveRecord::Base.connection.quote_table_name(model.table_name)
          sql_columns.push("#{associated_table}.#{column}")
        end

        "coalesce(#{sql_columns.join(', ')})"
      end
    end
  end
end
