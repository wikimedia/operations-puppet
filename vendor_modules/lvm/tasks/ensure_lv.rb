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

# Go and get the current details of the volume group. This will search for
# resources on the current system and return them in a native ruby format that
# we can easily interact with. The "find" method is expectng a string in the
# following format:
#    {resource type}/{resource title}
#
# This is exactly the same as the parameters you would pass to the
# `puppet resource` command, except in Ruby.
logical_volume = Puppet::Resource.indirection.find(
  "logical_volume/#{params['name']}",
)

# Prune parameters that we don't need
logical_volume.prune_parameters

# Set the settings we need
logical_volume[:ensure]           = params['ensure']           if params['ensure']
logical_volume[:name]             = params['name']             if params['name']
logical_volume[:volume_group]     = params['volume_group']     if params['volume_group']
logical_volume[:size]             = params['size']             if params['size']
logical_volume[:extents]          = params['extents']          if params['extents']
logical_volume[:persistent]       = params['persistent']       if params['persistent']
logical_volume[:thinpool]         = params['thinpool']         if params['thinpool']
logical_volume[:poolmetadatasize] = params['poolmetadatasize'] if params['poolmetadatasize']
logical_volume[:minor]            = params['minor']            if params['minor']
logical_volume[:type]             = params['type']             if params['type']
logical_volume[:range]            = params['range']            if params['range']
logical_volume[:stripes]          = params['stripes']          if params['stripes']
logical_volume[:stripesize]       = params['stripesize']       if params['stripesize']
logical_volume[:readahead]        = params['readahead']        if params['readahead']
logical_volume[:resize_fs]        = params['resize_fs']        if params['resize_fs']
logical_volume[:mirror]           = params['mirror']           if params['mirror']
logical_volume[:mirrorlog]        = params['mirrorlog']        if params['mirrorlog']
logical_volume[:alloc]            = params['alloc']            if params['alloc']
logical_volume[:no_sync]          = params['no_sync']          if params['no_sync']
logical_volume[:region_size]      = params['region_size']      if params['region_size']

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
