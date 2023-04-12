require 'beaker-rspec'
require 'beaker/module_install_helper'
require 'beaker/puppet_install_helper'
require 'voxpupuli/acceptance/spec_helper_acceptance'

$LOAD_PATH << File.join(__dir__, 'acceptance/lib')

RSpec.configure do |c|
  c.before :suite do
    unless ENV['BEAKER_provision'] == 'no'
      run_puppet_install_helper
      install_module_on(hosts)
      install_module_dependencies_on(hosts)
    end
  end
end

shared_context 'mount context' do |agent|
  let(:fs_file) { MountUtils.filesystem_file(agent) }
  let(:fs_type) { MountUtils.filesystem_type(agent) }
  let(:backup) { agent.tmpfile('mount-modify') }
  let(:name) { "pl#{rand(999_999).to_i}" }
  let(:name_w_slash) { "pl#{rand(999_999).to_i}\/" }
  let(:name_w_whitespace) { "pl#{rand(999).to_i} #{rand(999).to_i}" }

  before(:each) do
    on(agent, "cp #{fs_file} #{backup}", acceptable_exit_codes: [0, 1])
  end

  after(:each) do
    # umount disk image
    on(agent, "umount /#{name}", acceptable_exit_codes: (0..254))
    # delete disk image
    if %r{aix}.match?(agent['platform'])
      on(agent, "rmlv -f #{name}", acceptable_exit_codes: (0..254))
    else
      on(agent, "rm /tmp/#{name}", acceptable_exit_codes: (0..254))
    end
    # delete mount point
    on(agent, "rm -fr /#{name}", acceptable_exit_codes: (0..254))
    # restore the fstab file
    on(agent, "mv #{backup} #{fs_file}", acceptable_exit_codes: (0..254))
  end
end
