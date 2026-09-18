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
# [*vm_max_map_count*]
#   The `vm.max_map_count` kernel parameter. The maximum number of memory map
#   areas a process may have.
#   Default: 1048575

class cassandra::sysctl(
    Integer $vm_dirty_background_bytes = 0,
    Integer $vm_max_map_count = 1048575,
){
    # 05-cassandra.conf
    sysctl::parameters { 'cassandra':
        values   => {
            'vm.dirty_background_bytes' => $vm_dirty_background_bytes,
            'vm.max_map_count'          => $vm_max_map_count,
        },
        priority => 5,
    }
}
