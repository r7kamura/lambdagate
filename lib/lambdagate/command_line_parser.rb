require "lambdagate/command"
require "lambdagate/create_command"
require "lambdagate/deploy_command"
require "lambdagate/update_command"
require "lambdagate/usage_command"

module Lambdagate
  class CommandLineParser
    class << self
      # @param [Array<String>] argv
      # @return [Lambdagate::Command]
      def parse(argv)
        new(argv).parse
      end
    end

    # @param [Array<String>] argv
    def initialize(argv)
      @argv = argv
    end

    # @return [Lambdagate::Command]
    def parse
      command_class.new(@argv)
    end

    private

    # @return [Class]
    def command_class
      case @argv.first
      when "create"
        Lambdagate::CreateCommand
      when "deploy"
        Lambdagate::DeployCommand
      when "update"
        Lambdagate::UpdateCommand
      else
        Lambdagate::UsageCommand
      end
    end
  end
end
