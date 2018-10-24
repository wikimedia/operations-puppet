# Class: profile::toolforge::grid::node::compute::dedicated
#
# This configures the compute node as a general node dedicated to a tool
#
# Parameters: 
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# filtertags: toolforge
class profile::toolforge::grid::node::compute::dedicated(
    $dedicated_tool = hiera('node_dedicated_tool', undef),
) {

    include profile::toolforge::grid::node::compute

    if $dedicated_tool {
        sonofgridengine::join { "queues-${::fqdn}":
            sourcedir => "${profile::toolforge::base::collectors}/queues",
            list      => [ $dedicated_tool ],
        }

        # Having the collector in the instance means that, for the time
        # being, dedicated queues can have just the one one in them.

        sonofgridengine::collectors::queues { $dedicated_tool:
            store  => "${profile::toolforge::base::collectors}/queues",
            config => 'toollabs/gridengine/queue-dedicated.erb',
        }
    }

    class { '::sonofgridengine::exec_host':
        config  => 'profile/toolforge/grid/host-unrestricted.erb',
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
