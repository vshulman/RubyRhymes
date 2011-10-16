Gem::Specification.new do |s|
  s.name        = 'ruby_rhymes'
  s.version     = '0.1.1'
  s.date        = '2011-10-11'
  s.summary     = "A gem for producing poetry for the rest of us"
  s.description = "A gem for rhyming words and counting syllables on phrases"
  s.authors     = ["Vlad Shulman", "Thomas Kielbus"]
  s.email       = 'vladshulman@gmail.com'
  s.files       = Dir.glob("{lib,doc}/**/*") + %w(README.md)
  s.homepage    = 'https://github.com/vshulman/RubyRhymes'
end