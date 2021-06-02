# frozen_string_literal: true

module Censys
  class Error < StandardError; end

  class AuthenticationError < Error; end

  class NotFound < Error; end

  class Forbidden < Error; end

  class RateLimited < Error; end

  class InternalServerError < Error; end
end
