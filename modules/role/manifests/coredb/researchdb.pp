class role::coredb::researchdb(
    $shard='s1',
    $innodb_log_file_size = '2000M',
    $mariadb = false,
    $innodb_file_per_table = false
){
    class { 'role::coredb::common':
        shard                     => $shard,
        mariadb                   => $mariadb,
        innodb_log_file_size      => $innodb_log_file_size,
        read_only                 => false,
        disable_binlogs           => true,
        long_timeouts             => true,
        enable_unsafe_locks       => true,
        large_slave_trans_retries => true,
        innodb_file_per_table     => $innodb_file_per_table,
        # send researchdb icinga alerts to admins
        # and analytics icinga contact groups.
        contact_group             => 'admins,analytics',
    }
}
