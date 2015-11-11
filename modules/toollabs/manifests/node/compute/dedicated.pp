# Class: toollabs::node::compute::general
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
class toollabs::node::compute::dedicated {

    include toollabs::node

    if $::node_dedicated_tool {

        system::role { 'toollabs::node::compute::dedicated':
            description => "Computation node dedicated to ${::labsproject}.${::node_dedicated_tool}",
        }

        class { 'toollabs::queues': queues => [ $::node_dedicated_tool ] }

        # Having the collector in the instance means that, for the time
        # being, dedicated queues can have just the one one in them.

        gridengine::collectors::queues { $::node_dedicated_tool:
            store   => "${toollabs::collectors}/queues",
            config  => 'toollabs/gridengine/queue-dedicated.erb',
            require => Class['toollabs::queues'],
        }

    } else {

        system::role { 'toollabs::node::compute::dedicated':
            description => 'Unassigned dedicated computation node',
        }

    }

    class { 'gridengine::exec_host':
        config => 'toollabs/gridengine/host-unrestricted.erb',
    }

    file { '/usr/local/bin/jobkill':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/jobkill',
    }

}
