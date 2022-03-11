require 'master_manipulator'
require 'lvm_helper'
require 'securerandom'

test_name "FM-4614 - C96613 - remove physical volume"

#initilize
pv = '/dev/sdc'

pp = <<-MANIFEST
physical_volume {'#{pv}':
  ensure => present,
}
MANIFEST

pp2 = <<-MANIFEST
physical_volume {"Remove physical volume group: #{pv}":
  ensure  => absent,
  name    => '#{pv}',
}
MANIFEST

#creating physical volume
step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => pp)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step 'Run Puppet Agent to create physical volume'
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    on(agent, puppet('agent -t --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    step "Verify the physical volume is created: #{pv}"
    verify_if_created?(agent, 'physical_volume', pv)
  end
end

#removing the physical volume
step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => pp2)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step "run Puppet Agent to remove the physical volume: #{pv}"
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    on(agent, puppet('agent -t --environment production'), :acceptable_exit_codes => [0,2]) do |result|
      assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
    end

    step "Verify the physical volume is removed: #{pv}"
    on(agent, "pvdisplay") do |result|
      assert_no_match(/#{pv}/, result.stdout, 'Unexpected error was detected')
    end
  end
end
