# == Function: ipresolve( string $name_to_resolve, bool $ipv6 = false)
#
# Copyright (c) 2015 Wikimedia Foundation Inc.
#
# Performs a name resolution (for A AND AAAA records only) and returns
# an hash of arrays.
#
# Takes one or more names to resolve, and returns an array of all the
# A or AAAA records found. The resolution is actually only done when
# the ttl has expired. A particular nameserver can also be specified
# so only that is used, rather than the system default.
#
require 'yaml'

module Puppet::Parser::Functions
  path = '/var/lib/git/operations/puppet/modules/openstack/files/nfs-mounts-config.yaml'
  projects_config = YAML.load_file(path)
  newfunction(:nfs_mount_enabled, :type => :rvalue, :arity => 2) do |args|
    project_name = args[0]
    mount_name = args[1]
    if not projects_config.include?(project_name)
        false
    elsif projects_config[project_name] == 'all'
        true
    elsif projects_config[project_name].include(mount_name)
        true
    else
        false
    end
  end
end
