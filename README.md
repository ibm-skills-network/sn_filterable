# SnFilterable

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/sn_filterable`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sn_filterable'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install sn_filterable
    
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

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/sn_filterable.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
