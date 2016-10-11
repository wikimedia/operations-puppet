test_name 'FM-4614 - C97171 - Install the LVM module'

step 'Install LVM Module Dependencies'
on(master, puppet('module install puppetlabs-stdlib'))

step 'Install LVM Module'
proj_root = File.expand_path(File.join(File.dirname(__FILE__), '../../../'))
staging = { :module_name => 'puppetlabs-lvm' }
local = { :module_name => 'lvm', :source => proj_root, :target_module_path => master['distmoduledir'] }

# Check to see if module version is specified.
staging[:version] = ENV['MODULE_VERSION'] if ENV['MODULE_VERSION']

# in CI install from staging forge, otherwise from local
install_dev_puppet_module_on(master, options[:forge_host] ? staging : local)
