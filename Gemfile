source "https://rubygems.org"

ruby "3.4.4"

gem "rails", "~> 8.0.1"

# App server / assets
gem "puma", ">= 6.4"
gem "propshaft"
gem "bootsnap", require: false

# Database
gem "pg", "~> 1.5"

# Auth
gem "bcrypt", "~> 3.1.20"

# Rate limiting for the publicly hosted instance
gem "rack-attack", "~> 6.7"

gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
