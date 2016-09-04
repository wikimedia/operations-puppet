class role::coredb::s1( $mariadb = false, $innodb_file_per_table = false ) {
    class { 'role::coredb::common':
        shard                 => 's1',
        slow_query_digest     => false,
        mariadb               => $mariadb,
        innodb_file_per_table => $innodb_file_per_table,
        innodb_log_file_size  => '2000M'
    }
}
