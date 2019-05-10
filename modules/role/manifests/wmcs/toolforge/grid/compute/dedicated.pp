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
    system::role { $name:
        description => 'Toolforge dedicated computation node'
    }

    include ::profile::toolforge::base
    include ::profile::toolforge::apt_pinning
    include ::profile::toolforge::grid::base
    include ::profile::toolforge::grid::node::all
    include ::profile::toolforge::grid::node::compute::dedicated
    include ::profile::toolforge::grid::sysctl
    include ::profile::wmcs::services::oidentd::client
}
