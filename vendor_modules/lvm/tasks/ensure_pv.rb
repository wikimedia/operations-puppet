#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require 'json'
require 'yaml'
require 'puppet'

# Parse the parameters
params = JSON.parse($stdin.read)

defaults = {
  'force' => false
}

# Merge in the default values
params = defaults.merge(params)

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
physical_volume = Puppet::Resource.indirection.find(
  "physical_volume/#{params['name']}",
)

# Prune parameters that we don't need
physical_volume.prune_parameters

# Set the settings we need
physical_volume[:ensure]    = params['ensure']    if params['ensure']
physical_volume[:name]      = params['name']      if params['name']
physical_volume[:unless_vg] = params['unless_vg'] if params['unless_vg']
physical_volume[:force]     = params['force']     if params['force']

# Save the result
_resource, report = Puppet::Resource.indirection.save(physical_volume)

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
