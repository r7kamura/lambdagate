module Lambdagate
  class Command
    # @param [Array<String>] argv
    def initialize(argv)
      @argv = argv
    end

    # @note Override me
    def run
      raise NotImplementedError
    end
  end
end
