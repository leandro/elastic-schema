# -*- encoding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "elastic-schema"
  s.version     = '0.2.3'
  s.platform    = Gem::Platform::RUBY
  s.license     = "MIT"
  s.authors     = ["Leandro Camargo"]
  s.email       = "leandroico@gmail.com"
  s.homepage    = "http://github.com/leandro/elastic-schema"
  s.summary     = "Elasticsearch schema manager for Ruby"
  s.description = "A stateful way to approach Elasticsearch document mappings and data migrations"

  s.required_ruby_version = '>= 2.0'

  s.add_dependency 'elasticsearch-api'

  s.files            = `git ls-files -- lib/*`.split("\n")
  s.files           += ["License.txt"]
  s.executables      = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.extra_rdoc_files = [ "README.md" ]
  s.rdoc_options     = ["--charset=UTF-8"]
  s.require_path     = "lib"
end
