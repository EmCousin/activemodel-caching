# ActiveModel::Caching

A library providing easy-to-use object-level caching methods for various data types in a Ruby on Rails application, allowing you to cache different attribute types directly on your models.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activemodel-caching'
```

Then execute:

```bash
$ bundle install
```

## Configuration

Configure the gem in an initializer:

```ruby
ActiveModel::Caching.setup do |config|
  config.cache_store = Rails.cache # Defaults to Rails.cache if Rails is defined, otherwise to memory store
  config.global_id_app = 'MyApp'   # Defaults to GlobalID.app if present, otherwise to Rails.application.name if Rails is defined
end
```

## Usage

Include the module in your class:

```ruby
class User
  include ActiveModel::Caching

  cache_string :session_token
  cache_integer :view_count
  # ... etc
end
```

## Available Cache Types

### Basic Types

#### `cache_string`
Caches a string value.
```ruby
cache_string :session_token
# Generates:
# - session_token
# - session_token=
```

#### `cache_integer`
Caches an integer value.
```ruby
cache_integer :view_count
# Generates:
# - view_count
# - view_count=
```

#### `cache_decimal`
Caches a decimal value.
```ruby
cache_decimal :account_balance
# Generates:
# - account_balance
# - account_balance=
```

#### `cache_datetime`
Caches a datetime value.
```ruby
cache_datetime :last_login
# Generates:
# - last_login
# - last_login=
```

#### `cache_flag` / `cache_boolean`
Caches a boolean value.
```ruby
cache_flag :is_active
# or
cache_boolean :is_verified
# Generates:
# - is_active
# - is_active=
```

#### `cache_float`
Caches a float value.
```ruby
cache_float :average_rating
# Generates:
# - average_rating
# - average_rating=
```

### Complex Types

#### `cache_enum`
Caches an enum value, storing the value among defined options.
```ruby
cache_enum :status, %w[active inactive suspended]
# Generates:
# - status
# - status=
```

#### `cache_json`
Caches a JSON value.
```ruby
cache_json :user_preferences
# Generates:
# - user_preferences
# - user_preferences=
```

#### `cache_hash`
Caches a hash value.
```ruby
cache_hash :settings
# Generates:
# - settings
# - settings=
```

### Collections

#### `cache_list`
Caches an ordered list of values, maintaining order and optional limit.
```ruby
cache_list :recent_posts, limit: 5
# Generates:
# - recent_posts
# - add_to_recent_posts
# - remove_from_recent_posts
```

#### `cache_unique_list`
Caches a unique list of values, maintaining uniqueness and optional limit.
```ruby
cache_unique_list :favorite_articles, limit: 10
# Generates:
# - favorite_articles
# - add_to_favorite_articles
# - remove_from_favorite_articles
```

#### `cache_set`
Caches a set of unique values with optional limit.
```ruby
cache_set :tags, limit: 5
# Generates:
# - tags
# - add_to_tags
# - remove_from_tags
```

#### `cache_ordered_set`
Caches an ordered set of values, maintaining order and optional limit.
```ruby
cache_ordered_set :recent_views, limit: 10
# Generates:
# - recent_views
# - add_to_recent_views
# - remove_from_recent_views
```

### Special Types

#### `cache_slots`
Caches a limited number of available "slots" for resources like seats or reservations.
```ruby
cache_slots :seats, available: 10
# Generates:
# - seats
# - available_seats?
# - reserve_seats!
# - release_seats!
# - reset_seats!
```

#### `cache_slot`
Caches a single slot (binary available/taken resource).
```ruby
cache_slot :parking_space
# Generates:
# - parking_space
# - available_parking_space?
# - reserve_parking_space!
# - release_parking_space!
# - reset_parking_space!
```

#### `cache_counter`
Caches a counter value.
```ruby
cache_counter :likes_count
# Generates:
# - likes_count
# - increment_likes_count
# - decrement_likes_count
# - reset_likes_count
```

#### `cache_limiter`
Caches a limiter value with a maximum allowed count.
```ruby
cache_limiter :api_requests, limit: 100
# Generates:
# - api_requests
# - increment_api_requests
# - reset_api_requests
```

## Options

All cache methods accept an optional `expires_in` parameter:

```ruby
cache_string :session_token, expires_in: 1.hour
cache_counter :daily_visits, expires_in: 1.day
```

## Contributing

Bug reports and pull requests are welcome at https://github.com/EmCousin/activemodel-caching.

## License

This gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
```
