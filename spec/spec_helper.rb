# frozen_string_literal: true

require "coveralls"
Coveralls.wear!

require "dotenv/load"
require "rspec"
require "vcr"
require "censys"

ENV["CENSYS_ID"] = "foo" unless ENV.key?("CENSYS_ID")
ENV["CENSYS_SECRET"] = "bar" unless ENV.key?("CENSYS_SECRET")

CENSYS_ID = ENV["CENSYS_ID"] || "foo"
CENSYS_SECRET = ENV["CENSYS_SECRET"] || "bar"

def authorization_field
  require "base64"
  token = "#{CENSYS_ID}:#{CENSYS_SECRET}"
  "Basic #{Base64.strict_encode64(token)}"
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  config.filter_sensitive_data("<CENSORED>") { authorization_field }

  %w[CENSYS_ID CENSYS_SECRET CENSYS_EMAIL CENSYS_LOGIN].each do |key|
    config.filter_sensitive_data("<CENSORED>") { ENV[key] }
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
