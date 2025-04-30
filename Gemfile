source "https://rubygems.org"

gem "rails", "8.0.2"

gem "bootsnap", require: false
gem "deepsort"
gem "pg", "~> 1.5"
gem "publishing_platform_api_adapters"
gem "publishing_platform_app_config"
gem "publishing_platform_location"
gem "publishing_platform_sso"
gem "rack-cache"
gem "tzinfo-data", platforms: %i[mswin mswin64 mingw x64_mingw jruby]

group :development, :test do
  gem "climate_control"
  gem "debug", platforms: %i[mri mswin mswin64 mingw x64_mingw]
  gem "factory_bot_rails"
  gem "publishing_platform_rubocop"
  gem "publishing_platform_schemas"
  gem "publishing_platform_test"
  gem "rspec-rails"
  gem "timecop"
  gem "webmock", require: false
end

group :test do
  gem "simplecov"
end
