class role::coredb::es3( $mariadb = false ) {
    class { 'role::coredb::common':
        shard                 => 'es3',
        mariadb               => $mariadb,
        innodb_file_per_table => true,
        slow_query_digest     => false,
    }
}
