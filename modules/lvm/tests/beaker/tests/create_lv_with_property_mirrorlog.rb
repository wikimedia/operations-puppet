require 'master_manipulator'
require 'lvm_helper'
require 'securerandom'

test_name "FM-4614 - C96579 - create logical volume with property 'mirrorlog'"

#initilize
pv = ['/dev/sdc', '/dev/sdd']
vg = "VolumeGroup_" + SecureRandom.hex(2)
lv = ["LogicalVolume_" + SecureRandom.hex(3), \
      "LogicalVolume_" + SecureRandom.hex(3), \
      "LogicalVolume_" + SecureRandom.hex(3)]

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
  physical_volumes  => #{pv}
}
->
logical_volume{'#{lv[0]}':
  ensure        => present,
  volume_group  => '#{vg}',
  size          => '20M',
  mirror        => '1',
  mirrorlog     => 'core',
}
->
logical_volume{'#{lv[1]}':
  ensure        => present,
  volume_group  => '#{vg}',
  size          => '40M',
  mirror        => '1',
  mirrorlog     => 'disk',
}
->
logical_volume{'#{lv[2]}':
  ensure        => present,
  volume_group  => '#{vg}',
  size          => '100M',
  mirror        => '1',
  mirrorlog     => 'mirrored',
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

    step "Verify the logical volumes  are successfuly created: #{lv}"
    verify_if_created?(agent, 'logical_volume', lv[0], vg)
    verify_if_created?(agent, 'logical_volume', lv[1], vg)
    verify_if_created?(agent, 'logical_volume', lv[2], vg)

    step 'verify mirrorlog core (stored in mem):'
    on(agent, "lvs -a -o mirror_log /dev/#{vg}/#{lv[0]}") do |result|
      assert_match(/\s+/, result.stdout, "Unexpected error was detected")
    end

    step 'verify mirrorlog disk (stored in disk):'
    on(agent, "lvs -a -o mirror_log /dev/#{vg}/#{lv[1]}") do |result|
      assert_match(/#{lv}_mlog/, result.stdout, "Unexpected error was detected")
    end

    step 'verify mirrorlog mirrored (stored in disk):'
    on(agent, "lvs -a -o mirror_log /dev/#{vg}/#{lv[2]}") do |result|
      assert_match(/#{lv}_mlog/, result.stdout, "Unexpected error was detected")
    end
  end
end
