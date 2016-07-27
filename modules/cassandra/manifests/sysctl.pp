# == Class: cassandra::sysctl
#
# Configure sysctl parameters for Cassandra
#
# === Parameters
# [*vm_dirty_background_bytes*]
#   The `vm.dirty_background_bytes' kernel parameter
#   Default: 0

class cassandra::sysctl(
    $vm_dirty_background_bytes = 0,
){
    sysctl::parameters { 'cassandra':
        values => {
            'vm.dirty_background_bytes' => $vm_dirty_background_bytes,
        },
        priority => 5,
    }
}
