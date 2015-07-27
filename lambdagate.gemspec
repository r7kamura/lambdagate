lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "lambdagate/version"

Gem::Specification.new do |spec|
  spec.name          = "lambdagate"
  spec.version       = Lambdagate::VERSION
  spec.authors       = ["Ryo Nakamura"]
  spec.email         = ["r7kamura@gmail.com"]
  spec.summary       = "Management tool for Amazon API Gateway and Amazon Lambda."
  spec.homepage      = "https://github.com/r7kamura/lambdagate"
  spec.license       = "MIT"
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_runtime_dependency "aws-sdk", ">= 2.0.0"
  spec.add_runtime_dependency "aws4"
  spec.add_runtime_dependency "faraday", ">= 0.9.1"
  spec.add_runtime_dependency "swagger_parser"
end
