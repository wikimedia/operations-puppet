# Class: role::wmcs::toolforge::compute::dedicated
#
# This configures the compute node as a dedicated node
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
class role::wmcs::toolforge::grid::compute::dedicated {
    system::role { 'wmcs::toolforge::grid::compute::dedicated': description => 'Dedicated computation node' }

    include profile::toolforge::grid::base
    include profile::toolforge::grid::node::all
    include profile::toolforge::grid::node::compute::dedicated
}
