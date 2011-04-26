# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "webtopay/version"

Gem::Specification.new do |s|
  s.name        = "webtopay"
  s.version     = Webtopay::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Laurynas Butkus", "Kristijonas Urbaitis"]
  s.email       = ["laurynas.butkus@gmail.com", "kristis@micro.lt"]
  s.homepage    = "https://github.com/laurynas/webtopay"
  s.summary     = %q{Provides integration with http://www.webtopay.com (mokejimai.lt) payment system}
  s.description = %q{Verifies webtopay.com (mokejimai.lt) payment data transfer}

  s.rubyforge_project = "webtopay"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

