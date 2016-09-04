class role::coredb::es2( $mariadb = false ) {
    class { 'role::coredb::common':
        shard                 => 'es2',
        mariadb               => $mariadb,
        innodb_file_per_table => true,
        slow_query_digest     => false,
    }
}
