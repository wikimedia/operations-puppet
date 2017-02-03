# Class: role::toollabs::node::compute::general
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
class role::toollabs::node::compute::general {

    include ::toollabs::node::all

    system::role { 'toollabs::node::compute::general': description => 'General computation node' }

    class { '::gridengine::exec_host':
        config  => 'toollabs/gridengine/host-vmem.erb',
        require => File['/var/lib/gridengine'],
    }

    class { '::toollabs::hostgroups': groups => [ '@general' ] }
}
