# frozen_string_literal: true
require "view_component"
require "rails"

class SnFilterable::BaseComponents::BaseComponent < ViewComponent::Base
  include ClassNameHelper
  include FetchOrFallbackHelper

  def initialize(tag:, classes: nil, **system_arguments)
    @tag = tag
    @system_arguments = system_arguments

    # TODO
    # Implement a more native way of adding custom CSS class instead of stupid string concat
    # Similar to the Claasifier Primer build
    # https://github.com/primer/view_components/blob/41b277aa047ba7d1a669a48dc392115bf4948435/app/components/primer/base_component.rb
    @system_arguments[:class] = class_names(
      system_arguments[:class],
      classes
    )
  end

  def call
    content_tag(@tag, content, **@system_arguments)
  end
end
