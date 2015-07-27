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

    # @param [String] parent_id
    # @param [String] path_part
    # @param [String] restapi_id
    # @return [Faraday::Response]
    def create_resource(parent_id:, part:, restapi_id:)
      post("/restapis/#{restapi_id}/resources/#{parent_id}", pathPart: part).tap do |response|
        puts "[DEBUG] Created " + response.body["path"]
      end
    end

    # @param [Array<String>] paths
    # @param [String] restapi_id
    def create_resources(paths:, restapi_id:)
      root_resource_id = get_root_resource_id(restapi_id: restapi_id)
      paths.each do |path|
        parent_id = root_resource_id
        parts = path.split("/")
        parts[1..-1].each_with_index do |part, index|
          if resource = find_resource(path: parts[0 .. index + 1].join("/"), restapi_id: restapi_id)
            parent_id = resource["id"]
          else
            response = create_resource(
              parent_id: parent_id,
              part: part,
              restapi_id: restapi_id,
            )
            parent_id = response.body["id"]
          end
        end
      end
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

    # @param [String] restapi_id
    # @return [Faraday::Response]
    def list_resources(restapi_id:)
      get("/restapis/#{restapi_id}/resources")
    end

    # @param [false, true, nil] api_key_required
    # @param [String, nil] authorization_type
    # @param [String] http_method
    # @param [Hash{String => String}, nil] request_models
    # @param [Hash{String => String}, nil] request_parameters
    # @param [String] resource_id
    # @param [String] restapi_id
    # @return [Faraday::Response]
    def put_method(api_key_required: nil, authorization_type: nil, http_method:, request_models: nil, request_parameters: nil, resource_id:, restapi_id:)
      put(
        "/restapis/#{restapi_id}/resources/#{resource_id}/methods/#{http_method}",
        {
          apiKeyRequired: api_key_required,
          authorizationType: authorization_type,
          requestModels: request_models,
          requestParameters: request_parameters,
        }.reject { |key, value| value.nil? },
      )
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
    # @param [String] restapi_id
    # @return [Hash{String => Hash}, nil]
    def find_resource(path:, restapi_id:)
      list_resources(restapi_id: restapi_id).body["item"].find do |item|
        item["path"] == path
      end
    end

    # @param [String] path
    # @param [Hash, nil] params
    # @param [Hash, nil] headers
    # @return [Faraday::Response]
    def get(path, params = nil, headers = nil)
      process(:get, path, params, headers)
    end

    # @param [String] restapi_id
    # @return [String, nil]
    def get_root_resource_id(restapi_id:)
      list_resources(restapi_id: restapi_id).body["item"].find do |item|
        if item["path"] == "/"
          return item["id"]
        end
      end
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
