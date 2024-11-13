# frozen_string_literal: true

require_relative "caching/version"

require "base64"
require "bigdecimal/util"
require "json"
require "active_support"
require "active_support/time"

module ActiveModel
  # Provides with a set of methods allowing to cache data structures at the object level
  module Caching
    mattr_accessor :cache_store
    @@cache_store = ActiveSupport::Cache::MemoryStore.new

    class << self
      def setup
        yield self
      end
    end

    extend ActiveSupport::Concern

    class_methods do
      # Caches a string value for the given attribute.
      #
      # @param attribute_name [Symbol] the name of the string attribute to cache.
      # @param expires_in [ActiveSupport::Duration, nil] optional expiration time for the cache entry.
      #
      # @example
      #   cache_string :session_token
      def cache_string(attribute_name, expires_in: nil)
        define_method(attribute_name) do
          cache_store.read(cache_key_for(attribute_name))
        end

        define_method(:"#{attribute_name}=") do |value|
          cache_store.write(cache_key_for(attribute_name), value, expires_in: expires_in)
        end

        attribute_name
      end

      # Caches an integer value for the given attribute.
      #
      # @param attribute_name [Symbol] the name of the integer attribute to cache.
      # @param expires_in [ActiveSupport::Duration, nil] optional expiration time for the cache entry.
      #
      # @example
      #   cache_integer :view_count
      def cache_integer(attribute_name, expires_in: nil)
        define_method(attribute_name) do
          cache_store.read(cache_key_for(attribute_name)).to_i
        end

        define_method(:"#{attribute_name}=") do |value|
          cache_store.write(cache_key_for(attribute_name), value.to_i, expires_in: expires_in)
        end

        attribute_name
      end

      # Caches a decimal value for the given attribute.
      #
      # @param attribute_name [Symbol] the name of the decimal attribute to cache.
      # @param expires_in [ActiveSupport::Duration, nil] optional expiration time for the cache entry.
      #
      # @example
      #   cache_decimal :account_balance
      def cache_decimal(attribute_name, expires_in: nil)
        define_method(attribute_name) do
          cache_store.read(cache_key_for(attribute_name)).to_d
        end

        define_method(:"#{attribute_name}=") do |value|
          cache_store.write(cache_key_for(attribute_name), value.to_d, expires_in: expires_in)
        end

        attribute_name
      end

      # Caches a datetime value for the given attribute.
      #
      # @param attribute_name [Symbol] the name of the datetime attribute to cache.
      # @param expires_in [ActiveSupport::Duration, nil] optional expiration time for the cache entry.
      #
      # @example
      #   cache_datetime :last_login
      def cache_datetime(attribute_name, expires_in: nil)
        define_method(attribute_name) do
          cache_store.read(cache_key_for(attribute_name))&.to_time
        end

        define_method(:"#{attribute_name}=") do |value|
          cache_store.write(cache_key_for(attribute_name), value&.to_time, expires_in: expires_in)
        end

        attribute_name
      end

      # Caches a flag (boolean) value for the given attribute.
      #
      # @param attribute_name [Symbol] the name of the flag attribute to cache.
      # @param expires_in [ActiveSupport::Duration, nil] optional expiration time for the cache entry.
      #
      # @example
      #   cache_flag :is_active
      def cache_flag(attribute_name, expires_in: nil)
        define_method(attribute_name) do
          cache_store.read(cache_key_for(attribute_name)).present?
        end

        define_method(:"#{attribute_name}=") do |value|
          cache_store.write(cache_key_for(attribute_name), !!value, expires_in: expires_in)
        end

        attribute_name
      end

      # Caches a float value for the given attribute.
      #
      # @param attribute_name [Symbol] the name of the float attribute to cache.
      # @param expires_in [ActiveSupport::Duration, nil] optional expiration time for the cache entry.
      #
      # @example
      #   cache_float :average_rating
      def cache_float(attribute_name, expires_in: nil)
        define_method(attribute_name) do
          cache_store.read(cache_key_for(attribute_name)).to_f
        end

        define_method(:"#{attribute_name}=") do |value|
          cache_store.write(cache_key_for(attribute_name), value.to_f, expires_in: expires_in)
        end

        attribute_name
      end

      # Caches an enum value for the given attribute, storing the value among defined options.
      #
      # @param attribute_name [Symbol] the name of the enum attribute to cache.
      # @param options [Array] the list of acceptable values for the enum.
      # @param expires_in [ActiveSupport::Duration, nil] optional expiration time for the cache entry.
      #
      # @example
      #   cache_enum :status, %w[active inactive suspended]
      def cache_enum(attribute_name, options, expires_in: nil)
        define_method(attribute_name) do
          value = cache_store.read(cache_key_for(attribute_name))
          options.include?(value) ? value : options.first # Default to first option if invalid
        end

        define_method(:"#{attribute_name}=") do |value|
          raise ArgumentError, "Invalid value for #{attribute_name}" unless options.include?(value)

          cache_store.write(cache_key_for(attribute_name), value, expires_in: expires_in)
        end

        attribute_name
      end

      # Caches a JSON value for the given attribute.
      #
      # @param attribute_name [Symbol] the name of the JSON attribute to cache.
      # @param expires_in [ActiveSupport::Duration, nil] optional expiration time for the cache entry.
      #
      # @example
      #   cache_json :user_preferences
      def cache_json(attribute_name, expires_in: nil)
        define_method(attribute_name) do
          JSON.parse(cache_store.read(cache_key_for(attribute_name)) || nil.to_json, symbolize_names: true)
        end

        define_method(:"#{attribute_name}=") do |value|
          cache_store.write(cache_key_for(attribute_name), value.to_json, expires_in: expires_in)
        end

        attribute_name
      end

      # Caches a list of values for the given attribute, maintaining order and enforcing a limit.
      #
      # @param attribute_name [Symbol] the name of the list attribute to cache.
      # @param limit [Integer, nil] optional maximum number of items in the list.
      # @param expires_in [ActiveSupport::Duration, nil] optional expiration time for the cache entry.
      #
      # @example
      #   cache_list :recent_posts, limit: 5
      def cache_list(attribute_name, limit: nil, expires_in: nil)
        define_method(attribute_name) do
          cache_store.read(cache_key_for(attribute_name)) || []
        end

        define_method(:"add_to_#{attribute_name}") do |*values|
          list = send(attribute_name)
          values.each do |value|
            list << value
          end
          list.shift if limit && list.size > limit # Remove oldest item if limit is exceeded
          cache_store.write(cache_key_for(attribute_name), list, expires_in: expires_in)
        end

        define_method(:"remove_from_#{attribute_name}") do |*values|
          list = send(attribute_name)
          values.each do |value|
            list.delete(value)
          end
          cache_store.write(cache_key_for(attribute_name), list, expires_in: expires_in)
        end

        attribute_name
      end

      # Caches a unique list of values for the given attribute, maintaining uniqueness and enforcing a limit.
      #
      # @param attribute_name [Symbol] the name of the unique list attribute to cache.
      # @param limit [Integer, nil] optional maximum number of items in the list.
      # @param expires_in [ActiveSupport::Duration, nil] optional expiration time for the cache entry.
      #
      # @example
      #   cache_unique_list :favorite_articles, limit: 10
      def cache_unique_list(attribute_name, limit: nil, expires_in: nil)
        define_method(attribute_name) do
          cache_store.read(cache_key_for(attribute_name)) || []
        end

        define_method(:"add_to_#{attribute_name}") do |*values|
          unique_list = Set.new(send(attribute_name))
          values.each do |value|
            unique_list.add(value)
            if limit && unique_list.size > limit
              oldest_value = unique_list.to_a.shift # Remove the oldest item
              unique_list.delete(oldest_value)
            end
          end
          cache_store.write(cache_key_for(attribute_name), unique_list.to_a, expires_in: expires_in)
        end

        define_method(:"remove_from_#{attribute_name}") do |*values|
          unique_list = send(attribute_name)
          values.each do |value|
            unique_list.delete(value)
          end
          cache_store.write(cache_key_for(attribute_name), unique_list.to_a, expires_in: expires_in)
        end

        attribute_name
      end

      # Caches a set of unique values for the given attribute, maintaining uniqueness and enforcing a limit.
      #
      # @param attribute_name [Symbol] the name of the set attribute to cache.
      # @param limit [Integer, nil] optional maximum number of items in the set.
      # @param expires_in [ActiveSupport::Duration, nil] optional expiration time for the cache entry.
      #
      # @example
      #   cache_set :tags, limit: 5
      def cache_set(attribute_name, limit: nil, expires_in: nil)
        define_method(attribute_name) do
          Set.new(cache_store.read(cache_key_for(attribute_name)) || [])
        end

        define_method(:"add_to_#{attribute_name}") do |*values|
          set = send(attribute_name)
          values.each do |value|
            set.add(value)
            if limit && set.size > limit
              oldest_value = set.to_a.shift # Remove the oldest item
              set.delete(oldest_value)
            end
          end
          cache_store.write(cache_key_for(attribute_name), set.to_a, expires_in: expires_in)
        end

        define_method(:"remove_from_#{attribute_name}") do |*values|
          set = send(attribute_name)
          values.each do |value|
            set.delete(value)
          end
          cache_store.write(cache_key_for(attribute_name), set.to_a, expires_in: expires_in)
        end

        attribute_name
      end

      # Caches an ordered set of values for the given attribute, maintaining order and enforcing a limit.
      #
      # @param attribute_name [Symbol] the name of the ordered set attribute to cache.
      # @param limit [Integer, nil] optional maximum number of items in the ordered set.
      # @param expires_in [ActiveSupport::Duration, nil] optional expiration time for the cache entry.
      #
      # @example
      #   cache_ordered_set :recent_views, limit: 10
      def cache_ordered_set(attribute_name, limit: nil, expires_in: nil)
        define_method(attribute_name) do
          Set.new(cache_store.read(cache_key_for(attribute_name)) || [])
        end

        define_method(:"add_to_#{attribute_name}") do |*values|
          ordered_set = send(attribute_name)
          values.each do |value|
            ordered_set.delete(value)
            ordered_set.add(value)
            if limit && ordered_set.size > limit
              oldest_value = ordered_set.to_a.shift # Remove the oldest item
              ordered_set.delete(oldest_value)
            end
          end
          cache_store.write(cache_key_for(attribute_name), ordered_set, expires_in: expires_in)
        end

        define_method(:"remove_from_#{attribute_name}") do |*values|
          ordered_set = send(attribute_name)
          values.each do |value|
            ordered_set.delete(value)
          end
          cache_store.write(cache_key_for(attribute_name), ordered_set, expires_in: expires_in)
        end

        attribute_name
      end

      ##
      # Caches a limited number of available "slots" for the given attribute.
      # Slots represent a count of available resources, such as seats or reservations,
      # which can be reserved and released. This method generates several helper
      # methods to manage the slots, including checking availability, reserving a slot,
      # releasing a slot, and resetting the slots.
      #
      # @param attribute_name [Symbol] the name of the slot attribute to cache.
      # @param available [Integer] the maximum number of available slots.
      # @param expires_in [ActiveSupport::Duration, nil] optional expiration time for the cache entry.
      #
      # @example
      #   cache_slots :seats, available: 10
      #
      # This will generate the following methods:
      # - `seats`: retrieves the current number of taken slots.
      # - `available_seats?`: checks if there are any available slots left.
      # - `reserve_seats!`: reserves a slot if available, incrementing the taken count.
      # - `release_seats!`: releases a slot, decrementing the taken count.
      # - `reset_seats!`: resets the count of taken slots to zero.
      #
      # @return [Symbol] the name of the attribute.
      def cache_slots(attribute_name, available:, expires_in: nil)
        define_method(attribute_name) do
          cache_store.read(cache_key_for(attribute_name)).to_i
        end

        define_method(:"available_#{attribute_name}?") do
          taken = send(attribute_name)
          taken < available
        end

        define_method(:"reserve_#{attribute_name}!") do
          taken = send(attribute_name)
          if send(:"available_#{attribute_name}?")
            cache_store.write(cache_key_for(attribute_name), taken + 1, expires_in: expires_in)
            taken + 1
          else
            taken
          end
        end

        define_method(:"release_#{attribute_name}!") do
          taken = send(attribute_name)
          if taken.positive?
            cache_store.write(cache_key_for(attribute_name), taken - 1, expires_in: expires_in)
            taken - 1
          else
            taken
          end
        end

        define_method(:"reset_#{attribute_name}!") do
          taken = send(attribute_name)
          if taken.positive?
            cache_store.write(cache_key_for(attribute_name), 0, expires_in: expires_in)
          else
            taken
          end
        end

        attribute_name
      end

      ##
      # Caches a single slot for the given attribute.
      # A single slot represents a binary (available/taken) resource that can be reserved
      # or released, functioning similarly to {#cache_slots} with a fixed availability of 1.
      #
      # @param attribute_name [Symbol] the name of the slot attribute to cache.
      # @param expires_in [ActiveSupport::Duration, nil] optional expiration time for the cache entry.
      #
      # @example
      #   cache_slot :parking_space
      #
      # This will generate the following methods:
      # - `parking_space`: retrieves the current state (0 or 1).
      # - `available_parking_space?`: checks if the slot is available.
      # - `reserve_parking_space!`: reserves the slot if available.
      # - `release_parking_space!`: releases the slot.
      # - `reset_parking_space!`: resets the slot to zero (unreserved).
      #
      # @return [Symbol] the name of the attribute.
      def cache_slot(attribute_name, expires_in: nil)
        cache_slots(attribute_name, available: 1, expires_in: expires_in)
        attribute_name
      end

      # Caches a counter value for the given attribute.
      #
      # @param attribute_name [Symbol] the name of the counter attribute to cache.
      # @param expires_in [ActiveSupport::Duration, nil] optional expiration time for the cache entry.
      #
      # @example
      #   cache_counter :login_count
      def cache_counter(attribute_name, expires_in: nil)
        define_method(attribute_name) do
          cache_store.read(cache_key_for(attribute_name)).to_i
        end

        define_method(:"increment_#{attribute_name}") do
          new_value = send(attribute_name) + 1
          cache_store.write(cache_key_for(attribute_name), new_value, expires_in: expires_in)
        end

        define_method(:"reset_#{attribute_name}") do
          cache_store.write(cache_key_for(attribute_name), 0, expires_in: expires_in)
        end

        attribute_name
      end

      # Caches a limiter value for the given attribute, enforcing a limit.
      #
      # @param attribute_name [Symbol] the name of the limiter attribute to cache.
      # @param limit [Integer] the maximum allowed count.
      # @param expires_in [ActiveSupport::Duration, nil] optional expiration time for the cache entry.
      #
      # @example
      #   cache_limiter :api_requests, limit: 100
      def cache_limiter(attribute_name, limit:, expires_in: nil)
        define_method(attribute_name) do
          cache_store.read(cache_key_for(attribute_name)).to_i
        end

        define_method(:"increment_#{attribute_name}") do
          current_value = send(attribute_name)
          new_value = current_value + 1

          if new_value <= limit
            cache_store.write(cache_key_for(attribute_name), new_value, expires_in: expires_in)
            true # Increment successful
          else
            false # Increment failed due to limit
          end
        end

        define_method(:"reset_#{attribute_name}") do
          cache_store.write(cache_key_for(attribute_name), 0, expires_in: expires_in)
        end

        attribute_name
      end

      # Caches a hash for the given attribute.
      #
      # @param attribute_name [Symbol] the name of the hash attribute to cache.
      # @param expires_in [ActiveSupport::Duration, nil] optional expiration time for the cache entry.
      #
      # @example
      #   cache_hash :user_settings
      def cache_hash(attribute_name, expires_in: nil)
        define_method(attribute_name) do
          JSON.parse(cache_store.read(cache_key_for(attribute_name)) || "{}", symbolize_names: true)
        end

        define_method(:"#{attribute_name}=") do |value|
          cache_store.write(cache_key_for(attribute_name), value.to_json, expires_in: expires_in)
        end

        attribute_name
      end

      # Caches a boolean value for the given attribute.
      #
      # @param attribute_name [Symbol] the name of the boolean attribute to cache.
      # @param expires_in [ActiveSupport::Duration, nil] optional expiration time for the cache entry.
      #
      # @example
      #   cache_boolean :is_verified
      def cache_boolean(attribute_name, expires_in: nil)
        define_method(attribute_name) do
          cache_store.read(cache_key_for(attribute_name)).present?
        end

        define_method(:"#{attribute_name}=") do |value|
          cache_store.write(cache_key_for(attribute_name), !!value, expires_in: expires_in)
        end
      end
    end

    private

    # Generates a cache key for the given attribute.
    #
    # @param attribute_name [Symbol] the name of the attribute.
    # @return [String] the generated cache key.
    def cache_key_for(attribute_name)
      to_global_id(attribute_name: attribute_name)
    end
  end
end
