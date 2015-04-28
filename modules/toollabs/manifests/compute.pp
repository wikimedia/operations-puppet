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

    system::role { 'toollabs::node::compute::general':
        description => 'General computation node'
    }

    include toollabs::hba

    motd::script { 'exechost-banner':
        ensure   => present,
        source   => "puppet:///modules/toollabs/40-${::instanceproject}-exechost-banner",
    }

    class { 'gridengine::exec_host':
        config => 'toollabs/gridengine/host-vmem.erb',
    }

    class { 'toollabs::hostgroups': groups => [ '@general' ] }

    file { '/usr/local/bin/jobkill':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/jobkill',
    }

    # We want to have the new LVM managed layout only for the newly created
    # hosts, since the old ones have a wide variety of terrible-er layouts
    labs_lvm::volume { 'separate-tmp':
        size      => '16GB',
        mountat   => '/tmp',
        mountmode => '1777',
        options   => 'nosuid,noexec,nodev,rw',
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
