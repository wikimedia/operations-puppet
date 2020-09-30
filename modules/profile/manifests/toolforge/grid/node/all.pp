# Base class for all compute nodes

class profile::toolforge::grid::node::all(
    Boolean $swap_partition = lookup('swap_partition', {'default_value' => true}),
    Boolean $tmp_partition  = lookup('tmp_partition', {'default_value' => true}),
){

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
