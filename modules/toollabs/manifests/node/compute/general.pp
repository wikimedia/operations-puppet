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
class toollabs::node::compute::general (
    $separate_tmp = true,
){

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

    if $separate_tmp {
        # add seperate 16G /tmp! Note that this needs nodes to be at least
        # m1.large (80G total space). Old smaller nodes can keep their
        # /tmp on / by providing
        #   toollabs::node::compute::general::separate_tmp: false
        # via hiera.
        labs_lvm::volume { 'separate-tmp':
            size      => '16GB',
            mountat   => '/tmp',
            mountmode => '1777',
            options   => 'nosuid,noexec,nodev,rw',
        }
    }

    labs_lvm::swap { 'big':
        size => inline_template('<%= @memorysize_mb.to_i * 3 %>MB'),
    }
}
