# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'podspecpush/version'

Gem::Specification.new do |spec|
  spec.name          = "podspecpush"
  spec.version       = Podspecpush::VERSION
  spec.authors       = ["Joe Carroll"]
  spec.email         = ["jcarroll@mediafly.com"]

  spec.summary       = "Lint, publish and push podspec after tagging"
  spec.description   = "Once you tag a new version of your cocoapod run this to automatically run pod spec lint, pod push and finally update your local cocoapod spec file. All you must do is git tag!"
  spec.homepage      = "https://github.com/jcarroll-mediafly/podspecpush"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = ["podspecpush"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'trollop'
  spec.add_runtime_dependency 'colorize'

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
end
