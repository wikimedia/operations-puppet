# Class: toollabs::compute
#
# This role sets up a grid compute node in the Tool Labs model.
#
# On its own, this sets up a working node of the grid, but it is
# useless without a more specific role from toollabs::node::* that
# will add functionality and place it on queues or hostgroups.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::compute inherits toollabs {

    include toollabs::exec_environ,
            toollabs::hba,
            gridengine

    motd::script { 'exechost-banner':
        ensure => present,
        source => "puppet:///modules/toollabs/40-${::labsproject}-exechost-banner",
    }

    file { "${toollabs::store}/execnode-${::fqdn}":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File[$toollabs::store],
        content => "${::ipaddress}\n",
    }

}
