# ActiveModel::Caching

A library providing easy-to-use object-level caching methods for various data types in a Ruby on Rails application, allowing you to cache different attribute types directly on your models.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_model-caching'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install active_model-caching
```

## Usage

To use the caching methods provided by `ActiveModel::Caching`, include the module in your model and set up the cache store.

### Setup

You can set up a cache store globally in an initializer, for example, in `config/initializers/active_model_caching.rb`:

```ruby
ActiveModel::Caching.setup do |config|
  config.cache_store = ActiveSupport::Cache::MemoryStore.new # or any other cache store you prefer
end
```

If you're using Rails, you can also default to Rails cache if you prefer:
```ruby
ActiveModel::Caching.setup do |config|
  config.cache_store = Rails.cache
end
```

### Basic Usage

To enable caching for an attribute, simply call one of the `cache_*` methods in your model class. Here are the methods you can use:

- `cache_string` - Caches a string value.
- `cache_integer` - Caches an integer value.
- `cache_decimal` - Caches a decimal value.
- `cache_datetime` - Caches a datetime value.
- `cache_flag` - Caches a boolean flag.
- `cache_float` - Caches a float value.
- `cache_enum` - Caches an enumerated value.
- `cache_json` - Caches a JSON object.
- `cache_list` - Caches an ordered list with an optional limit.
- `cache_unique_list` - Caches a unique list with an optional limit.
- `cache_set` - Caches a unique set with an optional limit.
- `cache_ordered_set` - Caches an ordered set with an optional limit.
- `cache_slots` - Caches available "slots" (e.g., seats) with helper methods.
- `cache_slot` - Caches a single-slot availability.
- `cache_counter` - Caches a counter that can be incremented and reset.
- `cache_limiter` - Caches a limited counter, enforcing a maximum count.
- `cache_hash` - Caches a hash structure.
- `cache_boolean` - Caches a boolean value.

#### Example

Here’s how you might define a model with various cached attributes:

```ruby
class User
  include ActiveModel::Caching

  cache_string :session_token
  cache_integer :view_count
  cache_decimal :account_balance
  cache_datetime :last_login
  cache_flag :is_active
  cache_enum :status, %w[active inactive suspended]
  cache_json :preferences
  cache_list :recent_searches, limit: 10
  cache_set :tags, limit: 5
  cache_slots :seats, available: 100
  cache_counter :login_count
  cache_boolean :is_verified
end
```

With these, you’ll automatically have generated methods for interacting with the cache.

### Detailed Method Descriptions

- **`cache_string(attribute_name, expires_in: nil)`**: Caches a string attribute.
  - Example: `cache_string :username`

- **`cache_integer(attribute_name, expires_in: nil)`**: Caches an integer attribute.
  - Example: `cache_integer :view_count`

- **`cache_decimal(attribute_name, expires_in: nil)`**: Caches a decimal attribute.
  - Example: `cache_decimal :account_balance`

- **`cache_datetime(attribute_name, expires_in: nil)`**: Caches a datetime attribute.
  - Example: `cache_datetime :last_login`

- **`cache_flag(attribute_name, expires_in: nil)`**: Caches a boolean flag.
  - Example: `cache_flag :is_active`

- **`cache_enum(attribute_name, options, expires_in: nil)`**: Caches an enumerated value.
  - Example: `cache_enum :status, %w[active inactive suspended]`

- **`cache_json(attribute_name, expires_in: nil)`**: Caches a JSON object.
  - Example: `cache_json :user_preferences`

- **`cache_list(attribute_name, limit: nil, expires_in: nil)`**: Caches an ordered list, with an optional limit.
  - Example: `cache_list :recent_posts, limit: 5`

- **`cache_set(attribute_name, limit: nil, expires_in: nil)`**: Caches a unique set, with an optional limit.
  - Example: `cache_set :tags, limit: 10`

- **`cache_slots(attribute_name, available:, expires_in: nil)`**: Caches a set number of slots with helper methods.
  - Example: `cache_slots :seats, available: 100`

- **`cache_counter(attribute_name, expires_in: nil)`**: Caches a counter.
  - Example: `cache_counter :login_count`

- **`cache_boolean(attribute_name, expires_in: nil)`**: Caches a boolean value.
  - Example: `cache_boolean :is_verified`

### Example Methods

For each cached attribute, methods are generated for getting and setting values. For example:

```ruby
user = User.new

# Cache a string
user.session_token = "abc123"
puts user.session_token # => "abc123"

# Increment a counter
user.increment_login_count
puts user.login_count # => 1

# Reserve a slot
if user.available_seats?
  user.reserve_seats!
end

# Reset a slot
user.reset_seats!
```

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/your-username/active_model-caching](https://github.com/your-username/active_model-caching).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
