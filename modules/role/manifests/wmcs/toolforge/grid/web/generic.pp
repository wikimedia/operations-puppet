# Class: role::wmcs::toolforge::grid::web::generic
#
# This configures the web node as a generic node
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
class role::wmcs::toolforge::grid::web::generic {
    system::role { $name:
        description => 'Toolforge generic web exec node'
    }

    include ::profile::toolforge::base
    include ::profile::toolforge::apt_pinning
    include ::profile::toolforge::grid::base
    include ::profile::toolforge::grid::node::all
    include ::profile::toolforge::grid::node::web::generic
    include ::profile::toolforge::grid::sysctl
    include ::profile::wmcs::services::oidentd::client
}
