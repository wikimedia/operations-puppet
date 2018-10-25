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

    include profile::toolforge::grid::base
    include profile::toolforge::grid::node::all
    include profile::toolforge::grid::node::web::generic

    system::role { 'wmcs::toolforge::grid::web::generic': description => 'Generic web exec node' }
}
