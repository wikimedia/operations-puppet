# This role sets up a grid compute node in the Toolforge model.
#
# On its own, this sets up a working node of the grid, but it is
# useless without a more specific role from toollabs::node::* that
# will add functionality and place it on queues or hostgroups.

class toollabs::compute inherits toollabs {

    include ::gridengine
    include ::toollabs::exec_environ
    include ::toollabs::hba

    motd::script { 'exechost-banner':
        ensure => present,
        source => "puppet:///modules/toollabs/40-${::labsproject}-exechost-banner.sh",
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
