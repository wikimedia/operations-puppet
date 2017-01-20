# == Function: mount_nfs_volume( project, mount )
#
# Copyright (c) 2015 Wikimedia Foundation Inc.
#
# Returns true if the mount should be mounted in
# instance of the project
#
# Reads this information from labstore/files/nfs-mounts-config.yaml
# in the openstack module of operations/puppet.git
module Puppet::Parser::Functions
  @@labs_nfs_config_touched = nil
  @@labs_nfs_config = nil
  newfunction(:mount_nfs_volume, :type => :rvalue, :arity => 2) do |args|
    module_path = function_get_module_path(['labstore'])
    path = "#{module_path}/files/nfs-mounts.yaml"
    mtime = File.stat(path).mtime
    if @@labs_nfs_config_touched.nil? || mtime != @@labs_nfs_config_touched
        @@labs_nfs_config = function_loadyaml([path])
        @@labs_nfs_config_touched = mtime
    end
    config = @@labs_nfs_config['private']
    project = args[0]
    mount = args[1]
    if mount == 'any'
      # return true if any NFS mounts are mounted
      config[project]['mounts'].values.all?
    end
    if config.key?(project) && config[project].key?('mounts') \
        && config[project]['mounts'].key?(mount)
      config[project]['mounts'][mount]
    else
      false
    end
  end
end
