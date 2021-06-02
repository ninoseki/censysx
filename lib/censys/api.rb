# frozen_string_literal: true

require "censys/exceptions"

require "net/https"
require "json"
require "time"

module Censys
  #
  # Censys Search v2 API wrapper
  #
  class API
    VERSION = 2
    HOST = "search.censys.io"
    URL = "https://#{HOST}/api/v#{VERSION}/hosts"

    #
    # Initializes the API.
    #
    # @param [String] id the API UID used for authentication.
    #
    # @param [String] secret the API secret used for authentication.
    #
    # @raise [ArgumentError] either `id` or `secret` was `nil` or empty.
    #
    # @see https://censys.io/account
    #   Censys - My Account
    #
    def initialize(id = ENV["CENSYS_ID"], secret = ENV["CENSYS_SECRET"])
      raise(ArgumentError, "'id' argument is required") if id.nil? || id.empty?
      raise(ArgumentError, "'secret' argument is required") if secret.nil? || secret.empty?

      @id = id
      @secret = secret
    end

    #
    # View document from current index.
    #
    # View the current structured data we have on a specific document.
    # For more details, see our documentation: https://search.censys.io/api/v2/docs
    #
    # @param [String] document_id the ID of the document you are requesting.
    # @param [String, Time, nil] at_time Fetches a document at a given point in time.
    #
    # @return [Hash]
    #
    def view(document_id, at_time: nil)
      at_time = at_time.strftime("%Y-%m-%dT%H:%M:%S.%6NZ") if at_time.is_a?(Time)
      params = { at_time: at_time }.compact

      get("/#{document_id}", params) do |json|
        json
      end
    end

    #
    # Search current index.
    #
    # Searches the given index for all records that match the given query.
    # For more details, see our documentation: https://search.censys.io/api/v2/docs
    #
    # @param [String] query the query to be executed.
    # @params [Integer, nil] per_page the number of results to be returned for each page.
    # @params [Integer, nil] cursor the cursor of the desired result set.
    #
    # @return [Hash]
    #
    def search(query, per_page: nil, cursor: nil)
      params = { q: query, per_page: per_page, cursor: cursor }.compact
      get("/search", params) do |json|
        json
      end
    end

    #
    # Aggregate current index.
    #
    # Creates a report on the breakdown of the values of a field in a result set.
    # For more details, see our documentation: https://search.censys.io/api/v2/docs
    #
    # @param [String] query the query to be executed.
    # @param [String] field the field you are running a breakdown on.
    # @param [Integer, nil] num_buckets the maximum number of values. Defaults to 50.
    #
    # @return [Hash]
    #
    def aggregate(query, field, num_buckets: nil)
      params = { q: query, field: field, num_buckets: num_buckets }.compact
      get("/aggregate", params) do |json|
        json
      end
    end

    private

    #
    # Returns a URL for the API sub-path.
    #
    # @param [String] path the path relative to `/api/v2`.
    #
    # @return [URI::HTTPS] fully qualified URI.
    #
    def url_for(path)
      URI(URL + path)
    end

    #
    # Return HTTPS options
    #
    # @return [Hash]
    #
    def https_options
      proxy = ENV["HTTPS_PROXY"]

      return { use_ssl: true } unless proxy

      uri = URI(proxy)
      {
        proxy_address: uri.hostname,
        proxy_port: uri.port,
        proxy_from_env: false,
        use_ssl: true
      }
    end

    #
    # Sends the HTTP request and handles the response.
    #
    # @param [Net::HTTP::Get, Net::HTTP::Post] req the prepared request to send.
    #
    # @yield [json] the given block will be passed the parsed JSON.
    #
    # @yieldparam [Hash{String => Object}] json the parsed JSON.
    #
    # @raise [NotFound, RateLimited, InternalServerError, ResponseError]
    #   If an error response is returned, the appropriate exception will be
    #   raised.
    #
    def request(req)
      Net::HTTP.start(HOST, 443, https_options) do |http|
        response = http.request(req)

        json = JSON.parse(response.body)
        error = json["error"]

        case response.code
        when "200" then yield JSON.parse(response.body)
        when "302" then raise AuthenticationError, error
        when "403" then raise Forbidden, error
        when "404" then raise NotFound, error
        when "429" then raise RateLimited, error
        when "500" then raise InternalServerError, error
        else
          raise Error, error
        end
      end
    end

    #
    # Creates a new HTTP GET request.
    #
    # @param [String] path
    # @param [Hash] query parameters
    #
    # @see #request
    #
    def get(path, params, &block)
      url = url_for(path)
      url.query = URI.encode_www_form(params)

      get = Net::HTTP::Get.new(url)
      get.basic_auth @id, @secret

      request(get, &block)
    end
  end
end
