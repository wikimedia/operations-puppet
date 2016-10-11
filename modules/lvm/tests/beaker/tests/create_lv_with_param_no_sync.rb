require 'master_manipulator'
require 'lvm_helper'
require 'securerandom'

test_name "FM-4614 - C96581 - create logical volume with parameter 'no_sync'"

#initilize
pv = '/dev/sdc'
vg = "VolumeGroup_" + SecureRandom.hex(2)
lv = "LogicalVolume_" + SecureRandom.hex(3)

# Teardown
teardown do
  confine_block(:except, :roles => %w{master dashboard database}) do
    agents.each do |agent|
      remove_all(agent, pv, vg, lv)
    end
  end
end

pp = <<-MANIFEST
volume_group {'#{vg}':
  ensure            => present,
  physical_volumes  => '#{pv}',
}
->
logical_volume{'#{lv}':
  ensure        => present,
  volume_group  => '#{vg}',
  size          => '300M',
  no_sync       => true,
}
MANIFEST

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => pp)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step 'Run Puppet Agent to create logical volumes'
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    on(agent, puppet('agent -t --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    step "Verify the logical volume  is created: #{lv}"
    verify_if_created?(agent, 'logical_volume', lv, vg)
  end
end
