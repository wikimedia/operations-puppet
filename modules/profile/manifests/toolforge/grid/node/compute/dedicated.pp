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
# This class still requires the manual creation of a user_list on the grid master
# once the user_list is created with a name that matches the "node_dedicated_tool"
# hiera value, then you can use the puppet + grid-configurator with this, most
# likely.  It is not well tested yet and rarely used now.
# TODO: automate the user_list creation 
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
            config => 'profile/toolforge/grid/queue-dedicated.erb',
        }
    }

    class { '::sonofgridengine::exec_host':
        config  => 'profile/toolforge/grid/host-unrestricted.erb',
        require => File['/var/lib/gridengine'],
    }


    file { '/usr/local/bin/jobkill':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/jobkill',
    }

}
