# Base class for all compute nodes

class profile::toolforge::grid::node::all(
    Boolean $swap_partition = lookup('swap_partition', {'default_value' => true}),
    Boolean $tmp_partition  = lookup('tmp_partition', {'default_value' => true}),
){

    if $tmp_partition {
        cinderutils::ensure { 'separate-tmp':
            min_gb        => 15,
            max_gb        => 20,
            mount_point   => '/tmp',
            mount_mode    => '1777',
            mount_options => 'discard,x-systemd.device-timeout=2s,nosuid,noexec,nodev,rw',
        }
    }

    if $swap_partition {
        cinderutils::swap { 'big':
            min_gb => inline_template('<%= @memorysize_mb.to_i * 3 / 1024 %>'),
            max_gb => inline_template('<%= @memorysize_mb.to_i * 4 / 1024 %>'),
        }
    }
}
