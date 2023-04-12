dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join(dir, 'lib')

# Container for varous Puppet-specific RSpec helpers.
module PuppetSpec
end

require 'puppet_spec/files'
