[![Build Status](https://travis-ci.com/rreinhardt9/demux.svg?branch=master)](https://travis-ci.com/rreinhardt9/demux)

# Demux
Short description and motivation.

## Usage
How to use my plugin.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'demux'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install demux
```

## Contributing
After cloning repo:

- install gems `bundle install`
- set up the databases `bundle exec rake db:setup`
- If you run into trouble setting up databases because of a missing postgres role, you can create one by running `psql` and then running `ALTER ROLE postgres LOGIN CREATEDB;`
- If you cannot start `psql` because you are missing a database named after your local user, you can create one using `createdb`
- You should not be able to run the tests `bundle exec rake`

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
