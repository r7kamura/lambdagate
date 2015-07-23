require "aws4"
require "faraday"
require "openssl"
require "uri"

module Lambdagate
  class ApiGatewayClient
    DEFAULT_REGION = "us-east-1"

    class << self
      # @param [String] access_key
      # @param [String] body
      # @param [Hash] headers
      # @param [String] region
      # @param [String] request_method
      # @param [String] secret_key
      # @param [String] url
      # @return [Hash]  Request headers that includes Authorization header
      def sign(access_key:, body:, headers:, region:, request_method:, secret_key:, url:)
        AWS4::Signer.new(
          access_key: access_key,
          secret_key: secret_key,
          region: region,
        ).sign(
          request_method.upcase,
          URI(url),
          headers,
          body,
        )
      end
    end

    # @param [String] access_key
    # @param [String, nil] host
    # @param [String, nil] region
    # @param [String] secret_key
    def initialize(access_key:, host: nil, region: nil, secret_key:)
      @access_key = access_key
      @host = host
      @region = region
      @secret_key = secret_key
    end

    # @param [String] path
    # @param [Hash, nil] params
    # @param [Hash, nil] headers
    # @return [Faraday::Response]
    def delete(path, params = nil, headers = nil)
      process(:delete, path, params, headers)
    end

    # @param [String] path
    # @param [Hash, nil] params
    # @param [Hash, nil] headers
    # @return [Faraday::Response]
    def get(path, params = nil, headers = nil)
      process(:get, path, params, headers)
    end

    # @param [String] path
    # @param [Hash, nil] params
    # @param [Hash, nil] headers
    # @return [Faraday::Response]
    def patch(path, params = nil, headers = nil)
      process(:patch, path, params, headers)
    end

    # @param [String] path
    # @param [Hash, nil] params
    # @param [Hash, nil] headers
    # @return [Faraday::Response]
    def post(path, params = nil, headers = nil)
      process(:post, path, params, headers)
    end

    # @param [String] path
    # @param [Hash, nil] params
    # @param [Hash, nil] headers
    # @return [Faraday::Response]
    def put(path, params = nil, headers = nil)
      process(:put, path, params, headers)
    end

    private

    # @return [String]
    def base_url
      "https://#{host}"
    end

    # @return [Faraday::Connection]
    def connection
      @connection ||= Faraday::Connection.new(url: base_url)
    end

    # @return [String]
    def default_host
      "apigateway.#{region}.amazonaws.com"
    end

    # @return [Hash{String => String}]
    def default_request_headers
      {
        "Date" => Time.now.iso8601,
        "Host" => host,
      }
    end

    # @return [String]
    def host
      @host || default_host
    end

    # @param [Symbol] request_method
    # @param [String] path
    # @param [Hash, nil] params
    # @param [Hash, nil] headers
    # @return [Faraday::Response]
    def process(request_method, path, params, headers)
      headers = default_request_headers.merge(headers || {})
      connection.send(
        request_method,
        URI.escape(path),
        params,
        self.class.sign(
          access_key: @access_key,
          body: "", # TODO
          headers: headers,
          region: region,
          request_method: request_method.to_s,
          secret_key: @secret_key,
          url: "#{base_url}#{path}",
        ),
      )
    end

    # @return [String]
    def region
      @region || DEFAULT_REGION
    end
  end
end
