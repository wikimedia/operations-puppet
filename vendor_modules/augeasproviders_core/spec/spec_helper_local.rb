# frozen_string_literal: true

require 'pathname'
dir = Pathname.new(__FILE__).parent
$LOAD_PATH.unshift(dir, File.join(dir, 'lib'), File.join(dir, '..', 'lib'))

require 'augeas_spec'

include RSpec::Mocks::ExampleMethods
Puppet[:modulepath] = File.join(dir, 'fixtures', 'modules')

# Load all shared contexts and shared examples
Dir["#{dir}/support/**/*.rb"].sort.each { |f| require f }
