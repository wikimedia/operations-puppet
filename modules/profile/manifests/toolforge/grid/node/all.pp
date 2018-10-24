# Base class for all compute nodes

class profile::toolforge::grid::node::all(
    $swap_partition = hiera('swap_partition', true),
    $tmp_partition = hiera('tmp_partition', true),
) {
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
}
