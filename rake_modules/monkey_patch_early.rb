require 'rubygems'
# We are using puppet 5.5 which uses this deprecated function.  As such monkey patch it bak in
# This file needs to be loaded before puppet
# We use 2.7.0 as the min version to silence deprecation warnings
# the functions are not actually removed until ruby 3.0
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7.0')
  module URI
    def self.escape(*args)
      DEFAULT_PARSER.escape(*args)
    end

    def self.unescape(*args)
      DEFAULT_PARSER.unescape(*args)
    end
  end
end
