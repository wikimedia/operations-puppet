# Class: toollabs::node::compute::general
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
class toollabs::node::compute::general {

    include toollabs::node::all

    system::role { 'toollabs::node::compute::general': description => 'General computation node' }

    class { 'gridengine::exec_host':
        config => 'toollabs/gridengine/host-vmem.erb',
    }

    class { 'toollabs::hostgroups': groups => [ '@general' ] }

    file { '/usr/local/bin/jobkill':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/jobkill',
    }

}

