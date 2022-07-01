# This role sets up a grid compute node in the Toolforge model.
#
# On its own, this sets up a working node of the grid, but it is
# useless without a more specific role from profile::toolforge::grid::node::* that
# will add functionality and place it on queues or hostgroups.

class profile::toolforge::grid::node::compute (
    Stdlib::Unixpath $etcdir = lookup('profile::toolforge::etcdir'),
){
    include ::profile::toolforge::grid::exec_environ
    include ::profile::toolforge::grid::hba
    include ::profile::toolforge::grid::submit_host

    motd::script { 'exechost-banner':
        ensure => present,
        source => "puppet:///modules/profile/toolforge/40-${::labsproject}-exechost-banner.sh",
    }

    file { "${profile::toolforge::grid::base::store}/execnode-${facts['fqdn']}":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File[$profile::toolforge::grid::base::store],
        content => "${::ipaddress}\n",
    }
}
