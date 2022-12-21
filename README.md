# SnFilterable

Welcome to the Skills Network Filterable gem!

This gem provides a method for developers to quickly implement a customizable search and filter for their data with live-reloading.

Live examples of the gem's use can be viewed at [Skills Network's Author Workbench](https://author.skills.network), primarily under the [organizations tab](https://author.skills.network/organizations)

![](sn_filterable_demo.gif)

## Requirements

There are a couple key requirements for your app to be compatible with this gem:

1. You need to have [AlpineJS](https://alpinejs.dev/essentials/installation) loaded into the page where you plan to use SnFilterable
2. Your app needs to be running [TailwindCSS](https://tailwindcss.com/docs/guides/ruby-on-rails)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "sn_filterable", git: "https://github.com/ibm-skills-network/sn_filterable.git"
```

And then execute:
```bash
bundle install
```

##### Make the following adjustments to your codebase

1. Add the necessary translations and customize as desired
```yaml
# en.yml
en:
    # Other translations
    shared:
        filterable:
        view_filter_button: "View filters"
        results_per_page: "Results per page"
        clear_all: "Clear all"
        pagination:
            previous_page: "Previous"
            next_page: "Next"
```

2. Require the necessary JavaScript (dependent on AlpineJS being included with your App)
```javascript
// application.js converted to application.js.erb

// other imports
<%= SnFilterable.load_js %>
```

3. Configure your app's Tailwind to scan the gem
```javascript
// tailwind.config.js
const execSync = require('child_process').execSync;
const output = execSync('bundle show sn_filterable', { encoding: 'utf-8' });

module.exports = {
  // other config settings
  content: [
    // other content
    output.trim() + '/app/**/*.{erb,rb}'
  ]
  // other config settings
};
```

## Usage


#### The MainComponent: Search Bar and sidebar

The MainComponent is what is demo'd in the introduction. It consists of the search bar and a sidebar for filters.

If you only wish to use the Search bar an optional `show_sidebar: false` parameter can be passed to `SnFilterable::MainComponent` in the view.

There are three components which work to provide the text search functionality:

1. Filters in the given model:
```ruby
# model.rb
class Model < ApplicationRecord
    include SnFilterable::Filterable

    FILTER_SCOPE_MAPPINGS = {
        "search_name": :filter_by_name
        # 'search_name' will be referenced from the view
    }.freeze


    SORT_SCOPE_MAPPINGS = {
        "sort_name": :sort_by_name
        # 'sort_name' will be referenced from the controller
    }.freeze

    scope :filter_by_name, ->(search) { where(SnFilterable::WhereHelper.contains("name", search)) }
    scope :sort_by_name, -> { order :name }
    # 'name' is a string column defined on the Model

    # Model code...
end
```

2. Setting up the controller
* While `:default_sort` is an optional parameter it is recommended
```ruby
# models_controller.rb
@search = Model.filter(params:, default_sort: ["sort_name", :asc].freeze)
@models = @search.items
```

3. Rendering the ViewComponent
```html
<%= render SnFilterable::MainComponent.new(frame_id: "some_unique_id", filtered: @search, filters: [], search_filter_name: "search_name") do %>
    <% @models.each do |model| %>
        <%= model.name %>
    <% end %>
    <%= filtered_paginate @search %> # Kaminari Gem Pagination
<% end %>
```

#### The MainComponent: Adding filters to the sidebar

Adding filters to the sidebar requires changes to two files though we recommend storing the data across three files and will demsontrate as such.

1. Add filters to Model
```ruby
# app/models/model.rb
class Model < ApplicationRecord
    # inclusion statement from introduction

    FILTER_SCOPE_MAPPINGS = {
        # other filter scopes...
        "model_type_filter": :filter_by_type
    }.freeze
    # 'model_type_filter' will be referenced in step 2

    ARRAY_FILTER_SCOPES = %i[model_type_filter].freeze
    # safelist of all filters we will be rendering in our sidebar
    
    scope :filter_by_type, ->(model_type_input) { where(model_type: model_type_input) }
    # where 'model_type' is an attribute defined on Model
end
```

2. Create filter options
```ruby
# app/models/filter.rb
# We store in a filter.rb model, but you can store as desired
class Filter
  MODEL_FILTERS = [
    {
      multi: true,
      title: "Type",
      filter_name: "model_type_filter",
      filters: %w(Special Normal).map { |type| { name: type, value: type } }
      # Allows us to filter between 'Special' and 'Normal' model types
      # Note we recommend storing the %w(Special Normal) array at a central location for easier validation and manipulation
    }
  ].freeze
end
```

3. Render as part of our MainComponent
```html
<!-- Notice the addition of a non-empty 'filters' argument which references step 2 -->
<%= render SnFilterable::MainComponent.new(frame_id: "some_unique_id", filtered: @search, filters: Filter::MODEL_FILTERS, search_filter_name: "search_name") do %>
    <!-- display code.. -->
<% end %>
```

## Testing / Development

This gem using [RSpec](https://rspec.info) for testing. Tests can be running locally by first setting up the dummy database/app as follows:

```bash
docker compose up -d
cd spec/dummy
rails db:create
rails db:schema:load
```


Now the test suite can be run from the project root using 
```bash
bundle exec rspec
```

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/ibm-skills-network/sn_filterable).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
