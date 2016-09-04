class role::coredb::s6( $mariadb = false, $innodb_file_per_table = false ) {
    class { 'role::coredb::common':
        shard                 => 's6',
        slow_query_digest     => false,
        mariadb               => $mariadb,
        innodb_file_per_table => $innodb_file_per_table,
    }
}
