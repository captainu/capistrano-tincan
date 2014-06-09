# capistrano-tincan

[Tincan](https://github.com/captainu/tincan) integration for Capistrano.

**Please note**: this code is still untested — use at your own risk.

## Installation

Add this line to your application's Gemfile:

``` ruby
gem 'capistrano-tincan', group: :development
```

And then execute:

``` bash
$ bundle
```

Then require it in your `Capfile` or your `config/deploy.rb`:

``` ruby
require 'capistrano/tincan'
```

## Usage

The following tasks are provided:

- `tincan:stop`
- `tincan:start`
- `tincan:restart`
- `tincan:rolling_restart`

Note that `rolling_restart` is essentially the same as `restart`, as there is no support yet for concurrent Tincan processes.

## Contributing

1. Fork it ( https://github.com/captainu/capistrano-tincan/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new pull request
