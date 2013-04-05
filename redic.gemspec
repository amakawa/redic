# encoding: utf-8

Gem::Specification.new do |s|
  s.name              = "redic"
  s.version           = "0.0.2"
  s.summary           = "Lightweight Redis Client"
  s.description       = "Lightweight Redis Client"
  s.authors           = ["Michel Martens", "Cyril David"]
  s.email             = ["michel@soveran.com", "me@cyrildavid.com"]
  s.homepage          = "https://github.com/amakawa/redic"
  s.files             = `git ls-files`.split("\n")
  s.license           = "MIT"
  s.add_dependency "hiredis"
end
