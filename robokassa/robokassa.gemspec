# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
version = File.read(File.expand_path("../VERSION",__FILE__)).strip

Gem::Specification.new do |s|
  s.name        = "robokassa"
  s.version     = version
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Victor Zagorski aka shaggyone"]
  s.email       = ["victor@zagorski.ru"]
  s.homepage    = "http://github.com/shaggyone/robokassa"
  s.summary     = %q{This gem adds robokassa support to your app.}
  s.description = %q{
    Robokassa is payment system, that provides a single simple interface for payment systems popular in Russia.
    If you have customers in Russia you can use the gem.

    The first thing about this gem, is that it was oribinally designed for spree commerce. So keep it in mind. 
  }

  s.rubyforge_project = "robokassa"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "rails", ">= 3.0.7"

  s.add_development_dependency "rake"
  s.add_development_dependency "thor"
  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "rspec",   ">= 1.3.2"
end
