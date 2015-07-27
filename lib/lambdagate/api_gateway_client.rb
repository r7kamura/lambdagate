require "faraday"
require "faraday_middleware"
require "faraday_middleware/aws_signers_v4"

module Lambdagate
  class ApiGatewayClient
    DEFAULT_REGION = "us-east-1"
    SERVICE_NAME = "apigateway"

    # @param [String] access_key_id
    # @param [String, nil] host
    # @param [String, nil] region
    # @param [String] secret_access_key
    def initialize(access_key_id:, host: nil, region: nil, secret_access_key:)
      @access_key_id = access_key_id
      @host = host
      @region = region
      @secret_access_key = secret_access_key
    end

    # @param [String] name
    # @return [Faraday::Response]
    def create_restapi(name:)
      post("/restapis", name: name)
    end

    # @param [String] model_name
    # @param [String] restapi_id
    # @return [Faraday::Response]
    def delete_model(model_name:, restapi_id:)
      delete("/restapis/#{restapi_id}/models/#{model_name}")
    end

    private

    # @return [String]
    def base_url
      "https://#{host}"
    end

    # @return [Faraday::Connection]
    def connection
      @connection ||= Faraday::Connection.new(url: base_url) do |connection|
        connection.request :json
        connection.request(
          :aws_signers_v4,
          credentials: Aws::Credentials.new(@access_key_id, @secret_access_key),
          region: region,
          service_name: SERVICE_NAME,
        )
        connection.response :json, :content_type => /\bjson\b/
        connection.response :raise_error
        connection.adapter Faraday.default_adapter
      end
    end

    # @return [String]
    def default_host
      "#{SERVICE_NAME}.#{region}.amazonaws.com"
    end

    # @return [Hash{String => String}]
    def default_request_headers
      {
        "Host" => host,
        "X-Amz-Date" => Time.now.iso8601,
      }
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

    # @return [String]
    def host
      @host || default_host
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

    # @param [Symbol] request_method
    # @param [String] path
    # @param [Hash, nil] params
    # @param [Hash, nil] headers
    # @return [Faraday::Response]
    def process(request_method, path, params, headers)
      connection.send(
        request_method,
        path,
        params,
        headers,
      )
    end

    # @param [String] path
    # @param [Hash, nil] params
    # @param [Hash, nil] headers
    # @return [Faraday::Response]
    def put(path, params = nil, headers = nil)
      process(:put, path, params, headers)
    end

    # @return [String]
    def region
      @region || DEFAULT_REGION
    end
  end
end
