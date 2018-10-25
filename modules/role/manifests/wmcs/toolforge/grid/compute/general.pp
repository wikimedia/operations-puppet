# Class: role::toolforge::compute::general
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
# filtertags: toolforge
class role::wmcs::toolforge::grid::compute::general {

    include profile::toolforge::grid::base
    include profile::toolforge::grid::node::all
    include profile::toolforge::grid::node::compute::general

    system::role { 'wmcs::toolforge::grid::compute::general': description => 'General computation node' }
}
