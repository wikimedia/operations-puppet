require 'master_manipulator'
require 'lvm_helper'
require 'securerandom'

test_name "FM-4969 - C97713 - create physical volume on aix"

#initilize
pv = 'hdisk1'

pp = <<-MANIFEST
physical_volume {'#{pv}':
  ensure  => present,
}
MANIFEST

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => pp)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step 'Run Puppet Agent to create physical volume'
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    expect_failure('expected to faile due to FM-4911') do
      on(agent, "/opt/puppetlabs/puppet/bin/puppet agent -t --environment production", :acceptable_exit_codes => [1]) do |result|
        assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      end
    end

    step "Verify the physical volume  is created on AIX box: #{pv}"
    # comment out the below verify function due to FM-4911
    #verify_if_created?(agent, 'aix_physical_volume', pv)
  end
end
