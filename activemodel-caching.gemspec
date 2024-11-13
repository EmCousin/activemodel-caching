# frozen_string_literal: true

require_relative "lib/active_model/caching/version"

Gem::Specification.new do |spec|
  spec.name = "activemodel-caching"
  spec.version = ActiveModel::Caching::VERSION
  spec.authors = ["Emmanuel Cousin"]
  spec.email = ["emmanuel@hey.com"]

  spec.summary = "ActiveModel::Caching is a flexible gem for managing temporary data structures (scalars, lists, JSON) using a caching backend, typically Rails cache but adaptable to other solutions. It offers a simple, Rails-friendly API for efficient, transient data handling."
  spec.description = "ActiveModel::Caching is a versatile gem for managing structured, temporary data using a caching backend, typically Rails cache for Rails applications. This gem provides an easy-to-use API for storing, retrieving, and manipulating data structures like scalars, lists, and JSON, making it simple to handle transient data without adding extra dependencies."
  spec.homepage = "https://github.com/EmCousin/activemodel-caching"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 7.0"
  spec.add_dependency "base64", ">= 0.1"
  spec.add_dependency "bigdecimal", ">= 3.1.2"
  spec.add_dependency "json", ">= 2.8"

  spec.add_development_dependency "globalid", ">= 1.2"
end
