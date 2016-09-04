class role::coredb::m1( $mariadb = false ) {
    class { 'role::coredb::common':
        shard                 => 'm1',
        mariadb               => $mariadb,
        innodb_file_per_table => true,
    }
}
