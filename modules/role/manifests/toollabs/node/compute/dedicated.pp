# Class: role::toollabs::node::compute::general
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
# filtertags: labs-project-tools
class role::toollabs::node::compute::dedicated($dedicated_tool = $::node_dedicated_tool) {

    include ::toollabs::node::all

    if $dedicated_tool {

        system::role { 'toollabs::node::compute::dedicated':
            description => "Computation node dedicated to ${::labsproject}.${dedicated_tool}",
        }

        class { '::toollabs::queues': queues => [ $dedicated_tool ] }

        # Having the collector in the instance means that, for the time
        # being, dedicated queues can have just the one one in them.

        gridengine::collectors::queues { $dedicated_tool:
            store   => "${toollabs::collectors}/queues",
            config  => 'toollabs/gridengine/queue-dedicated.erb',
            require => Class['toollabs::queues'],
        }

    } else {

        system::role { 'toollabs::node::compute::dedicated':
            description => 'Unassigned dedicated computation node',
        }

    }

    class { '::gridengine::exec_host':
        config  => 'toollabs/gridengine/host-unrestricted.erb',
        require => File['/var/lib/gridengine'],
    }
}
