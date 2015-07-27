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
      paths = swagger.paths.map { |key, value| "#{swagger.base_path}#{key}" }
      api_gateway_client.create_resources(
        paths: paths,
        restapi_id: restapi_id,
      )
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
