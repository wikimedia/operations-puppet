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

    system::role { 'toollabs::node::compute::general': description => 'General computation node' }

    class { 'gridengine::exec_host':
        content => template('toollabs/gridengine/host-vmem.erb'),
    }

    class { 'toollabs::hostgroups': groups => [ '@general' ] }

}
