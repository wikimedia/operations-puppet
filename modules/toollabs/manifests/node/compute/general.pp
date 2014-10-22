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

    class { 'toollabs::hostgroup': groups => [ 'general' ] }

}
