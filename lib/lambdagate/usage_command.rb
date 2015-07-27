require "lambdagate/command"

module Lambdagate
  class UsageCommand < Command
    # @todo
    # @note Implementation for Lambdagate::Command
    def run
      abort "Usage: #{$0} [create|deploy|update] [command-specific-options]"
    end
  end
end
