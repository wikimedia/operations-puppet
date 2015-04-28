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
class toollabs::node::compute::general inherits toollabs {

    system::role { 'toollabs::node::compute::general': description => 'General computation node' }

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
}
