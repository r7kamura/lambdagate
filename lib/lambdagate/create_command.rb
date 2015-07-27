require "aws-sdk"
require "lambdagate/command"
require "swagger_parser"

module Lambdagate
  class CreateCommand < Command
    DEFAULT_MODEL_NAMES = %w(Empty Error)

    # @todo
    # @note Implementation for Lambdagate::Command
    def run
      puts "[DEBUG] Creating API"
      response = create_restapi
      restapi_id = response.body["id"]

      puts "[DEBUG] Deleting default models"
      delete_default_models(restapi_id: restapi_id)

      puts "[DEBUG] Creating resources"
      api_gateway_client.create_resources(
        paths: paths,
        restapi_id: restapi_id,
      )

      puts "[DEBUG] Creating methods"
      methods.each do |method|
        resource = api_gateway_client.find_resource(path: method[:path], restapi_id: restapi_id)
        api_gateway_client.put_method(
          api_key_required: method[:api_key_required],
          authorization_type: method[:authorization_type],
          http_method: method[:http_method],
          request_models: method[:request_models],
          request_parameters: method[:request_parameters],
          resource_id: resource["id"],
          restapi_id: restapi_id,
        )
      end
    end

    private

    # @return [String, nil]
    def access_key_id
      credentials.access_key_id
    end

    # @return [Lambdagate::ApiGatewayClient]
    def api_gateway_client
      @__api_gateway_client ||= Lambdagate::ApiGatewayClient.new(
        access_key_id: access_key_id,
        secret_access_key: secret_access_key,
      )
    end

    # @return [String]
    def api_name
      swagger.info.title
    end

    # @return [Faraday::Response]
    def create_restapi
      api_gateway_client.create_restapi(name: api_name)
    end

    # @return [Aws::Credentials]
    def credentials
      @__credentials ||= Aws::SharedCredentials.new.credentials
    end

    # @param [String] restapi_id
    # @return [Array<Faraday::Response>]
    def delete_default_models(restapi_id:)
      DEFAULT_MODEL_NAMES.map do |model_name|
        api_gateway_client.delete_model(restapi_id: restapi_id, model_name: model_name)
      end
    end

    # @return [Array<Hash>]
    def methods
      swagger.paths.flat_map do |path, path_object|
        path_object.operations.map do |operation|
          {
            api_key_required: !!operation.source["x-api-key-required"],
            authorization_type: operation.source["x-authorization-type"],
            http_method: operation.http_method,
            path: "#{swagger.base_path}#{path}",
            request_models: operation.source["x-request-models"],
            request_parameters: operation.source["x-request-parameters"],
          }
        end
      end
    end

    # @return [Array<String>]
    def paths
      swagger.paths.map { |key, value| "#{swagger.base_path}#{key}" }
    end

    # @return [String, nil]
    def secret_access_key
      credentials.secret_access_key
    end

    # @return [SwaggerParser::Swagger]
    def swagger
      @swagger ||= SwaggerParser::FileParser.parse(swagger_path)
    end

    # @todo
    # @return [String]
    def swagger_path
      "examples/swagger.yml"
    end
  end
end
