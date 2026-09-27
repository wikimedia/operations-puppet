# frozen_string_literal: true

dir = File.dirname(__FILE__)
$LOAD_PATH.unshift(File.join(dir, 'lib'))

require 'helpers'
require 'matchers'

RSpec.configure do |config|
  config.include Helpers
  config.include Matchers
end
