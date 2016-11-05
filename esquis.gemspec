# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'esquis/version'

Gem::Specification.new do |spec|
  spec.name          = "esquis"
  spec.version       = Esquis::VERSION
  spec.authors       = ["Yutaka HARA"]
  spec.email         = ["yutaka.hara.gmail.com"]

  spec.summary       = %q{Simple ruby-like language that compiles to LLVM IR}
  spec.homepage      = "https://github.com/yhara/esquis"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_dependency "racc", "~> 1.4"
  spec.add_dependency "thor", "~> 0.19"
end
