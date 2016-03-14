$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "em-bitcoin"
  s.version     = "0.01"
  s.license     = ["MIT"]
  s.authors     = ["redsquirrel"]
  s.email       = ["dave.hoover@gmail.com"]
  s.summary     = %q{Bitcoin Protocol using EventMachine}
  s.description = %q{Combining Ruby's popular EventMachine library with the ruby-bitcoin implementation to provide an extensible connector to the Bitcoin network.}
  s.homepage    = "https://github.com/redsquirrel/em-bitcoin"

  s.rubyforge_project = "em-bitcoin"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.required_rubygems_version = ">= 1.3.6"
end
