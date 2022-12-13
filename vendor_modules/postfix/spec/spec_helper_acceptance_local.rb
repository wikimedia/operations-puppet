# frozen_string_literal: true

require 'singleton'

class LitmusHelper
  include Singleton
  include PuppetLitmus
end

RSpec.configure do |c|
  c.before :suite do
    LitmusHelper.instance.run_shell('puppet module install puppetlabs/mailalias_core')
  end
end
