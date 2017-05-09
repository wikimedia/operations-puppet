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

        gridengine::queue { $dedicated_tool:
            config_path           => '/var/lib/gridengine/etc/queues',
            hostlist              => 'NONE', #FIXME: Make hostgroups for these queues
            seq_no                => 6,
            np_load_avg_threshold => 2.0,
            priority              => 10,
            qtype                 => 'BATCH',
            rerun                 => true,
            slots                 => 1000,
            ckpt_list             => 'continuous',
            owner_list            => $dedicated_tool,
            user_lists            => $dedicated_tool,
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

    file { '/usr/local/bin/jobkill':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/jobkill',
    }

}
