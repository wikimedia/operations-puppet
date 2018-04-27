# Class: profile::toolforge::grid::node::compute::general
#
# This configures the compute node as a general node
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# filtertags: labs-project-tools
class profile::toolforge::grid::node::compute::general {

    class { '::sonofgridengine::exec_host':
        config  => 'profile/toolforge/grid/host-vmem.erb',
        require => File['/var/lib/gridengine'],
    }

    sonofgridengine::join { "hostgroups-${::fqdn}":
        sourcedir => "${toollabs::collectors}/hostgroups",
        list      => [ '@general' ],
    }

    file { '/usr/local/bin/jobkill':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/jobkill',
    }

}

