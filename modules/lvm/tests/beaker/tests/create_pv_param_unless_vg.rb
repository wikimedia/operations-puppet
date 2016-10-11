require 'master_manipulator'
require 'lvm_helper'
require 'securerandom'

test_name "FM-4614 - C96593 - create physical volume with parameter 'unless_vg'"

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
volume_group {'#{vg}':
  ensure            => present,
  physical_volumes  => '#{pv[0]}',
}
->
physical_volume {'#{pv[1]}':
  ensure    => present,
  unless_vg => '#{vg}'
}
MANIFEST

pp2 = <<-MANIFEST
physical_volume {'#{pv[1]}':
  ensure    => present,
  unless_vg => 'non-existing-volume-group'
}
MANIFEST

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => pp)
inject_site_pp(master, get_site_pp_path(master), site_pp)


confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    #Run Puppet Agent with manifest pp
    step "Run Puppet Agent to create volume group '#{vg}' on physical volume '#{pv[0]}'"
    on(agent, puppet('agent -t --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    step "Verify the volume group is created: #{vg}"
    verify_if_created?(agent, 'volume_group', vg)

    step "Verify physical volume '#{pv[1]}' is NOT created since volume group '#{vg}' DOES exist"
    on(agent, "pvdisplay") do |result|
      assert_no_match(/#{pv[1]}/, result.stdout, 'Unexpected error was detected')
    end
  end
end

#Run Puppet Agent again with manifest pp2
step 'Inject "site.pp" on Master with new manifest'
site_pp = create_site_pp(master, :manifest => pp2)
inject_site_pp(master, get_site_pp_path(master), site_pp)

confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    step "Run Puppet Agent to create the physical volume '#{pv[1]}':"
    on(agent, puppet('agent -t --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    step "Verify physical volume '#{pv[1]}' is created since volume group 'non-existing-volume-group' DOES NOT exist"
    verify_if_created?(agent, 'physical_volume', pv[1])
  end
end
