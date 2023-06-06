require 'puppet'
require 'beaker-rspec'
require 'beaker/module_install_helper'
require 'beaker/puppet_install_helper'

$LOAD_PATH << File.join(__dir__, 'acceptance/lib')

def beaker_opts
  { debug: true, trace: true, expect_failures: true, acceptable_exit_codes: (0...256) }
end

def non_windows_agents
  agents.reject { |agent| agent['platform'].include?('windows') }
end

RSpec.configure do |c|
  c.before :suite do
    unless ENV['BEAKER_provision'] == 'no'
      run_puppet_install_helper
      install_module_on(hosts)
      install_module_dependencies_on(hosts)
    end
  end
end
