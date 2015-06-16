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
  @@module_path = Puppet::Module.find('openstack', compiler.environment).path
  @@labs_nfs_config = YAML.load_file("#{@@module_path}/files/nfs-mounts-config.yaml")
  newfunction(:mount_nfs_volume, :type => :rvalue, :arity => 2) do |args|
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
