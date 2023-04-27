# frozen_string_literal: true

module AugeasSpec end

class AugeasSpec::Error < StandardError
end

require 'augeas_spec/augparse'
require 'augeas_spec/fixtures'

RSpec.configure do |config|
  config.extend AugeasSpec::Augparse
  config.extend AugeasSpec::Fixtures
  config.include AugeasSpec::Augparse
  config.include AugeasSpec::Fixtures
end
