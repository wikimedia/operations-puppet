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
class toollabs::node::compute::general {

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

    # 16G /tmp for everyone! Note that we need new nodes to be at least a large (80G total space)
    labs_lvm::volume { 'separate-tmp':
        size      => '16GB',
        mountat   => '/tmp',
        mountmode => '1777',
        options   => 'nosuid,noexec,nodev,rw',
    }

    labs_lvm::swap { 'big':
        size => inline_template('<%= @memorysize_mb.to_i * 3 %>MB'),
    }

}
