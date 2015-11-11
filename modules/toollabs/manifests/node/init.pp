# Class: toollabs::node
#
# Base class for compute nodes
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::node inherits toollabs {
    if $::lsbdistcodename != "precise" {
        # precise has to be done manually according to Yuvi
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
}
