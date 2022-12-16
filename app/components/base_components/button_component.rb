# frozen_string_literal: true
require_relative "base_component"

class ButtonComponent < BaseComponent
  DEFAULT_BUTTON_TYPE = :default
  BUTTON_TYPE_MAPPINGS = {
    DEFAULT_BUTTON_TYPE => "shadow-sm border-gray-300 text-gray-700 bg-white hover:bg-gray-50 focus:ring-indigo-500",
    :primary => "shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:ring-indigo-500",
    :danger => "border-transparent text-red-700 bg-red-100 hover:bg-red-200 focus:ring-red-500",
    :disabled => "shadow-sm border-gray-300 text-gray-700 bg-gray-200 cursor-default"
  }.freeze
  BUTTON_TYPE_OPTIONS = BUTTON_TYPE_MAPPINGS.keys

  DEFAULT_VARIANT = :medium
  VARIANT_MAPPINGS = {
    :small => "px-3 py-2 text-sm leading-4 font-medium",
    DEFAULT_VARIANT => "px-4 py-2 text-sm font-medium",
    :large => "px-4 py-2 text-base font-medium"
  }.freeze
  VARIANT_OPTIONS = VARIANT_MAPPINGS.keys

  DEFAULT_TAG = :button
  TAG_OPTIONS = [DEFAULT_TAG, :a, :summary].freeze

  DEFAULT_TYPE = :button
  TYPE_OPTIONS = [DEFAULT_TYPE, :reset, :submit].freeze

  # @example 50|Button types
  #   <%= render(ButtonComponent.new) { "Default" } %>
  #   <%= render(ButtonComponent.new(button_type: :primary)) { "Primary" } %>
  #   <%= render(ButtonComponent.new(button_type: :danger)) { "Danger" } %>
  #
  # @example 50|Variants
  #   <%= render(ButtonComponent.new(variant: :small)) { "Small" } %>
  #   <%= render(ButtonComponent.new(variant: :medium)) { "Medium" } %>
  #   <%= render(ButtonComponent.new(variant: :large)) { "Large" } %>
  #
  # @param button_type [Symbol] <%= one_of(ButtonComponent::BUTTON_TYPE_OPTIONS) %>
  # @param variant [Symbol] <%= one_of(ButtonComponent::VARIANT_OPTIONS) %>
  # @param tag [Symbol] <%= one_of(ButtonComponent::TAG_OPTIONS) %>
  # @param type [Symbol] <%= one_of(ButtonComponent::TYPE_OPTIONS) %>
  def initialize(
    button_type: DEFAULT_BUTTON_TYPE,
    variant: DEFAULT_VARIANT,
    tag: DEFAULT_TAG,
    type: DEFAULT_TYPE,
    **arguments
  )
    @arguments = arguments
    @arguments[:tag] = tag || DEFAULT_TAG

    if @arguments[:tag] == :a
      @arguments[:role] = :button
    else
      @arguments[:type] = type
    end

    show_focus_ring = arguments[:show_focus_ring].nil? ? true : arguments[:show_focus_ring]
    focus_ring_class = show_focus_ring ? "focus:ring-2 focus:ring-offset-2" : ""

    @arguments[:classes] = class_names(
      "inline-flex items-center border rounded-md #{focus_ring_class} focus:outline-none disabled:opacity-50 disabled:cursor-not-allowed",
      BUTTON_TYPE_MAPPINGS[fetch_or_fallback(BUTTON_TYPE_OPTIONS, button_type, DEFAULT_BUTTON_TYPE)],
      VARIANT_MAPPINGS[fetch_or_fallback(VARIANT_OPTIONS, variant, DEFAULT_VARIANT)]
    )
  end

  def call
    render(BaseComponent.new(**@arguments)) { content }
  end
end
