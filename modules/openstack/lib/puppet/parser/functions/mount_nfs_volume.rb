# == Function: mount_nfs_volume( project, mount )
#
# Copyright (c) 2015 Wikimedia Foundation Inc.
#
# Returns true if the mount should be mounted in
# instance of the project
#
# Reads this information from openstack/files/nfs-mounts-config.yaml
# in the openstack module of operations/puppet.git
module Puppet::Parser::Functions
  @@labs_nfs_config_loaded = false
  @@labs_nfs_config = {}
  newfunction(:mount_nfs_volume, :type => :rvalue, :arity => 2) do |args|
    unless @@labs_nfs_config_loaded
      @@labs_nfs_config = function_loadyaml ["#{function_get_module_path ['openstack']}/files/nfs-mounts-config.yaml"]
      @@labs_nfs_config_loaded = true
    end
    config = @@labs_nfs_config
    project = args[0]
    mount = args[1]
    if config.has_key? project and config[project].has_key? mount
      config[project][mount]
    else
      false
    end
  end
end
