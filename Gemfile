source "https://rubygems.org"

ruby "3.4.2"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.5"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.5"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# JWT token handling
gem "jwt", "~> 2.9"

# AWS SDK for Cognito
gem "aws-sdk-cognitoidentityprovider", "~> 1.130"

# HTTP client for external API calls
gem "httparty", "~> 0.22.0"

# Environment variables
gem "dotenv-rails", "~> 3.1", groups: [ :development, :test ]

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.20"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors", "~> 2.0"

# Serialization
gem "active_model_serializers", "~> 0.10.14"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # RSpec for testing
  gem "rspec-rails", "~> 7.1"

  # Factory Bot for test data
  gem "factory_bot_rails", "~> 6.4"

  # Faker for generating test data
  gem "faker", "~> 3.5"

  # Database cleaner for test database
  gem "database_cleaner-active_record", "~> 2.2"

  # Shoulda matchers for RSpec
  gem "shoulda-matchers", "~> 6.4"

  # For debugging
  gem "pry-rails", "~> 0.3.11"
  gem "pry-byebug", "~> 3.10"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :test do
  # WebMock for stubbing HTTP requests
  gem "webmock", "~> 3.24"

  # SimpleCov for code coverage
  gem "simplecov", "~> 0.22.0", require: false

  # VCR for recording HTTP interactions
  gem "vcr", "~> 6.3"
end
