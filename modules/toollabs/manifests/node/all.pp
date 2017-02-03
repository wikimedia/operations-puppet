# Base class for all compute nodes

class toollabs::node::all(
    $swap_partition = true,
    $tmp_partition = true,
) {

    include ::toollabs

    if $tmp_partition {
        labs_lvm::volume { 'separate-tmp':
            size      => '16GB',
            mountat   => '/tmp',
            mountmode => '1777',
            options   => 'nosuid,noexec,nodev,rw',
        }
    }

    if $swap_partition {
        labs_lvm::swap { 'big':
            size => inline_template('<%= @memorysize_mb.to_i * 3 %>MB'),
        }
    }

    file { '/usr/local/bin/jobkill':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/jobkill',
    }
}
