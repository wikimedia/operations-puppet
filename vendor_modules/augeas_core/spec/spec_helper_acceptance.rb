require 'beaker-rspec'
require 'beaker/module_install_helper'
require 'beaker/puppet_install_helper'

RSpec.configure do |c|
  c.before :suite do
    unless ENV['BEAKER_provision'] == 'no'
      run_puppet_install_helper
      install_module_on(hosts)
      install_module_dependencies_on(hosts)
    end
  end
end
