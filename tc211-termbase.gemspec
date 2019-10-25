
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "tc211/termbase/version"

Gem::Specification.new do |spec|
  spec.name          = "tc211-termbase"
  spec.version       = Tc211::Termbase::VERSION
  spec.authors       = ["Ribose"]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = %q{Build scripts for the ISO/TC 211 Termbase}
  spec.description   = %q{Build scripts for the ISO/TC 211 Termbase}
  spec.homepage      = "https://open.ribose.com"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "creek"
  spec.add_runtime_dependency "relaton", "~> 0.5"

  spec.add_development_dependency "bundler", "~> 2.0.1"
  spec.add_development_dependency "debase"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "ruby-debug-ide"
end
