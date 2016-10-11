require 'master_manipulator'
require 'lvm_helper'
require 'securerandom'

test_name "FM-4614 - C96614 - remove volume_group"

#initilize
pv = '/dev/sdc'
vg = "VolumeGroup_" + SecureRandom.hex(3)

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
  ensure => present,
}
->
volume_group {"Create a volume group: #{vg}":
  ensure            => present,
  name              => '#{vg}',
  physical_volumes  => '#{pv}',
}
MANIFEST

pp2 = <<-MANIFEST
volume_group {"Remove a volume group: #{vg}":
  ensure  => absent,
  name    => '#{vg}',
}
MANIFEST

#creating group
step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => pp)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step 'Run Puppet Agent to create volume group'
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    on(agent, puppet('agent -t --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    step "Verify the volume group is created: #{vg}"
    verify_if_created?(agent, 'volume_group', vg)
  end
end

#removing group
step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => pp2)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step "run Puppet Agent to remove volume group : #{vg}"
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    on(agent, puppet('agent -t --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    step "Verify the volume group is removed: #{vg}"
    on(agent, "vgdisplay") do |result|
      assert_no_match(/#{vg}/, result.stdout, 'Unexpected error was detected')
    end
  end
end
