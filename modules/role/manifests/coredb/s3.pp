class role::coredb::s3( $mariadb = false, $innodb_file_per_table = false ) {
    class { 'role::coredb::common':
        shard                 => 's3',
        slow_query_digest     => false,
        mariadb               => $mariadb,
        innodb_file_per_table => $innodb_file_per_table,
    }
}
