#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require 'json'
require 'puppet'

# Parse the parameters
params = JSON.parse($stdin.read)

# Set parameters to local variables and resolve defaults if required
size                = params['size']
logical_volume_name = params['logical_volume']
volume_group_name   = params['volume_group']

# If size is set to full, pass nil
size = '100%' if size == 'full'

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
logical_volume = Puppet::Resource.indirection.find(
  "logical_volume/#{logical_volume_name}",
)

throw "Logical volume #{logical_volume_name} not found" if logical_volume[:ensure] == :absent
throw "Logical volume #{logical_volume_name} not in volume group #{volume_group_name}" if logical_volume[:volume_group] != volume_group_name

# Prune parameters that we don't need
logical_volume.prune_parameters

# Set the settings we need
logical_volume[:size] = size

# Save the result
_resource, report = Puppet::Resource.indirection.save(logical_volume)

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
