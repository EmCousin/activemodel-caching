# frozen_string_literal: true

require "test_helper"
require "active_support"
require "globalid"

module ActiveModel
  class TestCaching < ActiveSupport::TestCase
    class VersionTest < self
      test "it has a version number" do
        refute_nil ::ActiveModel::Caching::VERSION
      end
    end

    class CachingTest < self
      class TestModel
        include Caching
        include GlobalID::Identification

        attr_accessor :id

        def initialize(id)
          @id = id
        end
      end

      def setup
        GlobalID.app = "active-model-caching"
      end

      def teardown
        ActiveModel::Caching.cache_store.clear
      end

      # Test cache_string
      def test_cache_string
        TestModel.cache_string :name
        @instance = TestModel.new(1)
        @instance.name = "John Doe"
        assert_equal "John Doe", @instance.name
      end

      # Test cache_integer
      def test_cache_integer
        TestModel.cache_integer :view_count
        @instance = TestModel.new(1)
        @instance.view_count = 42
        assert_equal 42, @instance.view_count
      end

      # Test cache_decimal
      def test_cache_decimal
        TestModel.cache_decimal :balance
        @instance = TestModel.new(1)
        @instance.balance = 99.99
        assert_equal BigDecimal("99.99"), @instance.balance
      end

      # Test cache_datetime
      def test_cache_datetime
        TestModel.cache_datetime :last_login
        @instance = TestModel.new(1)
        @instance.last_login = Time.current
        assert_in_delta Time.current, @instance.last_login, 1.second
      end

      # Test cache_flag
      def test_cache_flag
        TestModel.cache_flag :is_active
        @instance = TestModel.new(1)
        @instance.is_active = true
        assert @instance.is_active
      end

      # Test cache_float
      def test_cache_float
        TestModel.cache_float :average_rating
        @instance = TestModel.new(1)
        @instance.average_rating = 4.5
        assert_equal 4.5, @instance.average_rating
      end

      # Test cache_enum
      def test_cache_enum
        TestModel.cache_enum :status, %w[active inactive suspended]
        @instance = TestModel.new(1)
        @instance.status = "active"
        assert_equal "active", @instance.status

        assert_raises(ArgumentError) { @instance.status = "unknown" }
      end

      # Test cache_json
      def test_cache_json
        TestModel.cache_json :preferences
        @instance = TestModel.new(1)
        @instance.preferences = { theme: "dark" }
        assert_equal({ theme: "dark" }, @instance.preferences)
      end

      # Test cache_list
      def test_cache_list
        TestModel.cache_list :recent_posts, limit: 3
        @instance = TestModel.new(1)
        @instance.add_to_recent_posts("Post 1", "Post 2", "Post 3", "Post 4")
        assert_equal ["Post 2", "Post 3", "Post 4"], @instance.recent_posts
        @instance.remove_from_recent_posts("Post 4")
        assert_equal ["Post 2", "Post 3"], @instance.recent_posts
      end

      # Test cache_unique_list
      def test_cache_unique_list
        TestModel.cache_unique_list :favorite_articles, limit: 3
        @instance = TestModel.new(1)
        @instance.add_to_favorite_articles("Article 1", "Article 2", "Article 3")
        @instance.add_to_favorite_articles("Article 2") # Should not add duplicate
        @instance.add_to_favorite_articles("Article 4")
        assert_equal ["Article 2", "Article 3", "Article 4"], @instance.favorite_articles
        @instance.remove_from_favorite_articles("Article 4")
        assert_equal ["Article 2", "Article 3"], @instance.favorite_articles
      end

      # Test cache_set
      def test_cache_set
        TestModel.cache_set :tags, limit: 3
        @instance = TestModel.new(1)
        @instance.add_to_tags("tag1", "tag2", "tag3", "tag4")
        assert_equal Set.new(%w[tag2 tag3 tag4]), @instance.tags
        @instance.remove_from_tags("tag4")
        assert_equal Set.new(%w[tag2 tag3]), @instance.tags
      end

      # Test cache_ordered_set
      def test_cache_ordered_set
        TestModel.cache_ordered_set :recent_views, limit: 3
        @instance = TestModel.new(1)
        @instance.add_to_recent_views("Page 1", "Page 2", "Page 3", "Page 4", "Page 3")
        assert_equal Set.new(["Page 2", "Page 4", "Page 3"]), @instance.recent_views
        @instance.remove_from_recent_views("Page 3")
        assert_equal Set.new(["Page 2", "Page 4"]), @instance.recent_views
      end

      # Test cache_slot
      def test_cache_slot
        TestModel.cache_slot :parking_slot
        @instance = TestModel.new(1)

        assert_equal 0, @instance.parking_slot
        assert @instance.available_parking_slot?

        @instance.reserve_parking_slot!
        assert_equal 1, @instance.parking_slot
        refute @instance.available_parking_slot?

        @instance.release_parking_slot!
        assert_equal 0, @instance.parking_slot
        assert @instance.available_parking_slot?

        @instance.reserve_parking_slot!
        @instance.reserve_parking_slot!
        @instance.reserve_parking_slot!
        assert_equal 1, @instance.parking_slot
        refute @instance.available_parking_slot?

        @instance.reset_parking_slot!
        assert_equal 0, @instance.parking_slot
        assert @instance.available_parking_slot?
      end

      # Test cache_slots
      def test_cache_slots
        TestModel.cache_slots :parking_slots, available: 3
        @instance = TestModel.new(1)

        assert_equal 0, @instance.parking_slots
        assert @instance.available_parking_slots?

        @instance.reserve_parking_slots!
        @instance.reserve_parking_slots!
        assert_equal 2, @instance.parking_slots
        assert @instance.available_parking_slots?

        @instance.release_parking_slots!
        assert_equal 1, @instance.parking_slots
        assert @instance.available_parking_slots?

        @instance.reserve_parking_slots!
        @instance.reserve_parking_slots!
        @instance.reserve_parking_slots!
        assert_equal 3, @instance.parking_slots
        refute @instance.available_parking_slots?

        @instance.reset_parking_slots!
        assert_equal 0, @instance.parking_slots
        assert @instance.available_parking_slots?
      end

      # Test cache_counter
      def test_cache_counter
        TestModel.cache_counter :login_count
        @instance = TestModel.new(1)
        @instance.increment_login_count
        @instance.increment_login_count
        assert_equal 2, @instance.login_count
        @instance.reset_login_count
        assert_equal 0, @instance.login_count
      end

      # Test cache_limiter
      def test_cache_limiter
        TestModel.cache_limiter :api_requests, limit: 2
        @instance = TestModel.new(1)
        assert @instance.increment_api_requests
        assert @instance.increment_api_requests
        assert_not @instance.increment_api_requests # Should fail due to limit
        assert_equal 2, @instance.api_requests
      end

      # Test cache_hash
      def test_cache_hash
        TestModel.cache_hash :user_settings
        @instance = TestModel.new(1)
        @instance.user_settings = { notifications: true }
        assert_equal({ notifications: true }, @instance.user_settings)
      end

      # Test cache_boolean
      def test_cache_boolean
        TestModel.cache_boolean :is_verified
        @instance = TestModel.new(1)
        @instance.is_verified = true
        assert @instance.is_verified
      end
    end
  end
end
