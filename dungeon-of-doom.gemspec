$:.push File.expand_path('../lib', __FILE__)
require 'dungeon_of_doom/version'

Gem::Specification.new do |s|
  s.name        = 'dungeon-of-doom'
  s.version     = DungeonOfDoom::VERSION
  s.author      = 'Brian Chiha'
  s.email       = 'brian.chiha@gmail.com'
  s.summary     = 'Dungeon of Doom RPG game based off the BBC BASIC version'
  s.description = "Dungeon of Doom is an RPG game the was firstly published by Usborne in 1984 with the book 'Write Your Own Fantasy Games (Usborne Computers & Electronics)'.  This is a ruby rewrite"
  s.platform    = Gem::Platform::RUBY
  s.required_ruby_version = '>=1.8.2'
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)
end
