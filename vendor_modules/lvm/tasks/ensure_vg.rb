#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require 'json'
require 'puppet'

# Parse the parameters
params = JSON.parse($stdin.read)

# Set parameters to local variables and resolve defaults if required
name             = params['name']
puppet_ensure    = params['ensure']
createonly       = params['createonly'] || false
followsymlinks   = params['followsymlinks'] || false
physical_volumes = params['physical_volumes']

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
volume_group = Puppet::Resource.indirection.find(
  "volume_group/#{name}",
)

# Prune parameters that we don't need
volume_group.prune_parameters

# Set the settings we need
volume_group[:name]             = name
volume_group[:ensure]           = puppet_ensure
volume_group[:createonly]       = createonly
volume_group[:followsymlinks]   = followsymlinks
volume_group[:physical_volumes] = physical_volumes

# Save the result
_resource, report = Puppet::Resource.indirection.save(volume_group)

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
