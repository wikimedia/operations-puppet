require 'puppetlabs_spec_helper/module_spec_helper'
require 'pathname'
dir = Pathname.new(__FILE__).parent
$LOAD_PATH.unshift(dir, dir + 'lib', dir + '../lib')

require 'mocha'
require 'puppet'
require 'rspec'
require 'helpers'
require 'matchers'

RSpec.configure do |config|
    config.mock_with :mocha
    config.include Helpers
    config.include Matchers
end

# We need this because the RAL uses 'should' as a method.  This
# allows us the same behaviour but with a different method name.
class Object
    alias :must :should
end
