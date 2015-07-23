require "faraday"
require "openssl"
require "uri"

module Lambdagate
  class ApiGatewayClient
    DEFAULT_REGION = "us-east-1"

    # @param [String, nil] host
    # @param [String, nil] region
    def initialize(host: nil, region: nil)
      @host = host
      @region = region
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

    # @return [String]
    def host
      @host || default_host
    end

    # @param [String] request_method
    # @param [String] path
    # @param [Hash, nil] params
    # @param [Hash, nil] headers
    # @return [Faraday::Response]
    def process(request_method, path, params, headers)
      connection.send(
        request_method,
        URI.escape(path),
        params,
        headers,
      )
    end

    # @return [String]
    def region
      @region || DEFAULT_REGION
    end

    # @return [Hash{String => String}]
    def request_headers
      {
        "Authorization" => signature,
        "Host" => host,
        "X-Amz-Date" => Time.now.iso8601,
      }
    end

    # @todo
    # @return [String]
    def signature
      "TODO"
    end
  end
end
