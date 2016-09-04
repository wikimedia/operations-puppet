class role::coredb::fundraising( $mariadb = true ) {
    class { 'role::coredb::common':
        shard                 => 'fundraisingdb',
        logical_cluster       => 'fundraising',
        mariadb               => $mariadb,
        innodb_file_per_table => true,
        slow_query_digest     => false,
        heartbeat_enabled     => false
    }
}
