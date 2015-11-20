# Class: toollabs::node::all
#
# Base class for all compute nodes
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::node::all {

    include toollabs

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
