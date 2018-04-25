# == Class: cassandra::sysctl
#
# Configure sysctl parameters for Cassandra
#
# === Usage
# class { '::cassandra::sysctl':
#     vm_dirty_background_bytes => <num>,
# }
#
# === Parameters
# [*vm_dirty_background_bytes*]
#   The `vm.dirty_background_bytes' kernel parameter
#   Default: 0

class cassandra::sysctl(
    $vm_dirty_background_bytes = 0,
    $vm_max_map_count = 65530,
){
    if (!is_integer($vm_dirty_background_bytes)) {
        fail('vm_dirty_background_bytes must be a number')
    }

    # 05-cassandra.conf
    sysctl::parameters { 'cassandra':
        values   => {
            'vm.dirty_background_bytes' => $vm_dirty_background_bytes,
            'vm.max_map_count'          => $vm_max_map_count,
        },
        priority => 5,
    }
}
