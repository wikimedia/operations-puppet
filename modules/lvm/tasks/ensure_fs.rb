#!/opt/puppetlabs/puppet/bin/ruby
require 'json'
require 'puppet'

# Parse the parameters
params = JSON.parse(STDIN.read)

# Load all of Puppet's settings
Puppet.initialize_settings

# Set Puppet's user to root
Puppet.settings[:user]  = '0'
Puppet.settings[:group] = '0'

# Create an empty resource object
filesystem = Puppet::Resource.new(
  "Filesystem[#{params['name']}]",
)

# Prune parameters that we don't need
filesystem.prune_parameters

# Set the settings we need
filesystem[:ensure]              = params['ensure']              if params['ensure']
filesystem[:fs_type]             = params['fs_type']             if params['fs_type']
filesystem[:name]                = params['name']                if params['name']
filesystem[:mkfs_cmd]            = params['mkfs_cmd']            if params['mkfs_cmd']
filesystem[:options]             = params['options']             if params['options']
filesystem[:initial_size]        = params['initial_size']        if params['initial_size']
filesystem[:size]                = params['size']                if params['size']
filesystem[:ag_size]             = params['ag_size']             if params['ag_size']
filesystem[:large_files]         = params['large_files']         if params['large_files']
filesystem[:compress]            = params['compress']            if params['compress']
filesystem[:frag]                = params['frag']                if params['frag']
filesystem[:nbpi]                = params['nbpi']                if params['nbpi']
filesystem[:logname]             = params['logname']             if params['logname']
filesystem[:logsize]             = params['logsize']             if params['logsize']
filesystem[:maxext]              = params['maxext']              if params['maxext']
filesystem[:mountguard]          = params['mountguard']          if params['mountguard']
filesystem[:agblksize]           = params['agblksize']           if params['agblksize']
filesystem[:extended_attributes] = params['extended_attributes'] if params['extended_attributes']
filesystem[:encrypted]           = params['encrypted']           if params['encrypted']
filesystem[:isnapshot]           = params['isnapshot']           if params['isnapshot']
filesystem[:mount_options]       = params['mount_options']       if params['mount_options']
filesystem[:vix]                 = params['vix']                 if params['vix']
filesystem[:log_partitions]      = params['log_partitions']      if params['log_partitions']
filesystem[:nodename]            = params['nodename']            if params['nodename']
filesystem[:accounting]          = params['accounting']          if params['accounting']
filesystem[:mountgroup]          = params['mountgroup']          if params['mountgroup']
filesystem[:atboot]              = params['atboot']              if params['atboot']
filesystem[:perms]               = params['perms']               if params['perms']
filesystem[:device]              = params['device']              if params['device']
filesystem[:volume_group]        = params['volume_group']        if params['volume_group']

# Save the result
_resource, report = Puppet::Resource.indirection.save(filesystem)

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
