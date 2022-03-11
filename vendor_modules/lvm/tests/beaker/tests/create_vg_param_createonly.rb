require 'master_manipulator'
require 'lvm_helper'
require 'securerandom'

test_name "FM-4614 - C96596 - create volume group with parameter 'createonly'"

#initilize
pv = ['/dev/sdc', '/dev/sdd']
vg = "VolumeGroup_" + SecureRandom.hex(3)

# Teardown
teardown do
  confine_block(:except, :roles => %w{master dashboard database}) do
    agents.each do |agent|
      remove_all(agent, pv, vg)
    end
  end
end

pp = <<-MANIFEST
physical_volume {'#{pv[0]}':
  ensure => present,
}
->
volume_group {"#{vg}":
  ensure            => present,
  physical_volumes  => '#{pv[0]}',
}

MANIFEST

pp2 = <<-MANIFEST
physical_volume {'#{pv[1]}':
  ensure => present,
}
->
volume_group {"#{vg}":
  ensure            => present,
  physical_volumes  => '#{pv[1]}',
  createonly        => true,
}

MANIFEST

#Create volume group
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

    step "Verify the volume group '#{vg}' associated with physical volume '#{pv[0]}' :"
    on(agent, "pvdisplay #{pv[0]}") do |result|
      assert_match(/#{vg}/, result.stdout, "Unexpected error was detected")
    end
  end
end

#Make sure the volume group is unchange with 'createonly'
step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => pp2)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step 'Attempt to create a same name volume group with createonly'
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    on(agent, puppet('agent -t --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    step "Verify the volume group '#{vg}' still associated with physical volume '#{pv[0]}' :"
    on(agent, "pvdisplay #{pv[0]}") do |result|
      assert_match(/#{vg}/, result.stdout, "Unexpected error was detected")
    end

    step "verify the volume group '#{vg}' IS NOT  associated with physical volume '#{pv[1]}' :"
    on(agent, "pvdisplay #{pv[1]}") do |result|
      assert_no_match(/#{vg}/, result.stdout, "Unexpected error was detected")
    end
  end
end
