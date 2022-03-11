#!/opt/puppetlabs/puppet/bin/ruby
require 'json'
require 'puppet'

# Parse the parameters
# params = JSON.parse(STDIN.read)
params = JSON.parse(STDIN.read)

# Set parameters to local variables and resolve defaults if required
volume_group   = params['volume_group']
logical_volume = params['logical_volume']
mountpoint     = params['mountpoint']
options        = params['options']
atboot         = params['atboot']
fstype         = params['fstype']
owner          = params['owner']
group          = params['group']
mode           = params['mode']

# Check if we are managing any permissions
permissions_set = !(owner.nil? && group.nil? && mode.nil?)

# Load all of Puppet's settings
Puppet.initialize_settings

# Set Puppet's user to root
Puppet.settings[:user]  = '0'
Puppet.settings[:group] = '0'

# Go and get the current details of the volume group. This will search for
# resources on the current system and return them in a native ruby format that
# we can easily interact with. The "find" method is expectng a string in the
# following format:
#    {resource type}/{resource title}
#
# This is exactly the same as the parameters you would pass to the
# `puppet resource` command, except in Ruby.

# Create the directory for the mountpoint
`mkdir -p #{mountpoint}`

if permissions_set
  # Set permissions
  mount_file_resource = Puppet::Resource.new(
    "File[#{mountpoint}]",
  )

  mount_file_resource[:ensure] = :directory
  mount_file_resource[:owner]  = owner if owner
  mount_file_resource[:group]  = group if group
  mount_file_resource[:mode]   = mode if mode

  # Execute the permissions change
  _resource, report = Puppet::Resource.indirection.save(mount_file_resource)

  # If it fails, print the error and exit
  if report.resource_statuses.values[0].failed
    report.logs.each do |log|
      puts log.to_report
    end
    exit 1
  end
end

# Mount the logical volume
mount_resource = Puppet::Resource.new(
  "Mount[#{mountpoint}]",
)

mount_resource[:ensure]  = 'mounted'
mount_resource[:options] = options if options
mount_resource[:atboot]  = atboot if atboot
mount_resource[:fstype]  = fstype if fstype
mount_resource[:device]  = "/dev/#{volume_group}/#{logical_volume}"

# Save the result
_resource, report = Puppet::Resource.indirection.save(mount_resource)

# Print the logs
resource_status = report.resource_statuses.values[0]

exit_code = if resource_status.failed
              1
            else
              0
            end

if resource_status.events.empty?
  puts 'unchanged'
else
  report.logs.each do |log|
    puts log.to_report
  end
end

exit exit_code
