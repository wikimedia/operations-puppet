require 'master_manipulator'
require 'lvm_helper'
test_name "FM-4614 - C96592 - create physical volume parameter 'force'"

#initilize
pv = '/dev/sdc'

# Teardown
teardown do
  confine_block(:except, :roles => %w{master dashboard database}) do
    agents.each do |agent|
      remove_all(agent, pv)
    end
  end
end

pp = <<-MANIFEST
physical_volume {'#{pv}':
  ensure  => present,
  force   => true,
}
MANIFEST

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => pp)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step 'Run Puppet Agent to create physical volumes'
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    on(agent, puppet('agent -t --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    step "Verify the physical volume  is created: #{pv}"
    verify_if_created?(agent, 'physical_volume', pv)
  end
end
