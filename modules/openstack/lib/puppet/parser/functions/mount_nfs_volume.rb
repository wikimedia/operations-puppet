# == Function: mount_nfs_volume( project_name, volume_name )
#
# Copyright (c) 2015 Wikimedia Foundation Inc.
#
# Returns true if the volume volume_name should be mounted in
# instance of the project project_name.
#
# Reads this information from openstack/files/nfs-mounts-config.yaml
# in the openstack module of operations/puppet.git
require 'yaml'

module Puppet::Parser::Functions
  path = '/var/lib/git/operations/puppet/modules/openstack/files/nfs-mounts-config.yaml'
  newfunction(:mount_nfs_volume, :type => :rvalue, :arity => 2) do |args|
    projects_config = YAML.load_file(path)
    project_name = args[0]
    mount_name = args[1]
    if not projects_config.include?(project_name)
        false
    elsif projects_config[project_name].include?(mount_name)
        projects_config[project_name][mount_name]
    else
        false
    end
  end
end
