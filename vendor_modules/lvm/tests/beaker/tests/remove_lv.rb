require 'master_manipulator'
require 'lvm_helper'
require 'securerandom'

test_name "FM-4614 - C96615 - remove logical volume"

#initilize
pv = '/dev/sdc'
vg = "VolumeGroup_" + SecureRandom.hex(2)
lv = "LogicalVolume_" + SecureRandom.hex(3)

# Teardown
teardown do
  confine_block(:except, :roles => %w{master dashboard database}) do
    agents.each do |agent|
      remove_all(agent, pv, vg)
    end
  end
end

pp = <<-MANIFEST
physical_volume {'#{pv}':
  ensure  => present,
}
->
volume_group {'#{vg}':
  ensure            => present,
  physical_volumes  => '#{pv}',
}
->
logical_volume{'#{lv}':
  ensure        => present,
  volume_group  => '#{vg}',
  size          => '100M',
}
MANIFEST

pp2 = <<-MANIFEST
logical_volume {'#{lv}':
  ensure        => absent,
  volume_group  => '#{vg}',
}
MANIFEST

#Creating a logical volume
step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => pp)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step 'Run Puppet Agent to create logical volumes'
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    on(agent, "umount /dev/#{vg}/#{lv}", :acceptable_exit_codes => [0,1])
    on(agent, puppet('agent -t --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    step "Verify the logical volume  is created: #{lv}"
    verify_if_created?(agent, 'logical_volume', lv, vg)
  end
end

#removing the logical volume
step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => pp2)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step "run Puppet Agent to remove logical volume : #{lv}"
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    on(agent, puppet('agent -t --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    step "Verify the logical volume  is removed: #{lv}"
    on(agent, "lvdisplay") do |result|
      assert_no_match(/#{lv}/, result.stdout, 'Unexpected error was detected')
    end
  end
end
