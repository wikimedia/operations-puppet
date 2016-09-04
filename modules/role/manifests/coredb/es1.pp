class role::coredb::es1( $mariadb = false ) {
    class { 'role::coredb::common':
        shard                 => 'es1',
        mariadb               => $mariadb,
        innodb_file_per_table => true,
        slow_query_digest     => false,
        heartbeat_enabled     => false,
    }
}
