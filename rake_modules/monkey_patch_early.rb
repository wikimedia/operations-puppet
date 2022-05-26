require 'rubygems'
# We are using puppet 5.5 which uses this deprecated function.  As such monkey patch it bak in
# This file needs to be loaded before puppet
# We use 2.7.0 as the min version to silence deprecation warnings
# the function is not actually removed untill ruby 3.0
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7.0')
  module URI
    def self.escape(*args)
      DEFAULT_PARSER.escape(*args)
    end
  end
end
