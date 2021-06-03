# Censysx

[![Gem Version](https://badge.fury.io/rb/censysx.svg)](https://badge.fury.io/rb/censysx)

A Censys Search v2 API wrapper for Ruby. 💎

- [Official API Docs](https://search.censys.io/api)

## Installation

```bash
gem install censysx
```

## Usage

Initialize the API:

```ruby
require "censys"

api = Censys::API.new(id, secret)
```

You can initialize the API by using `$CENSYS_ID` and `$CENSYS_SECRET` environment variables:

```ruby
# in this case, it tries to load ID and secret from ENV
# - ENV["CENSYS_ID"] for the ID
# - ENV["CENSYS_SECRET"] for the secret
api = Censys::API.new
```

View:

```ruby
response = api.view("1.1.1.1")
response = api.view("1.1.1.1", at_time: "2021-03-01T00:00:00.000000Z")
```

Search:

```ruby
response = api.search(query, cursor: cursor)
```

Search with cursor:

```ruby
cursor = nil

loop do
  response = api.search(query, cursor: cursor)

  links = response.dig("result", "links")
  cursor = links["next"]
  break if cursor == ""
end
```

Aggregate:

```ruby
response = api.aggregate(query, field)
response = api.aggregate(query, field, num_buckets: num_buckets)
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
