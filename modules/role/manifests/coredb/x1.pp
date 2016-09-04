class role::coredb::x1( $mariadb = true ) {
    class { 'role::coredb::common':
        shard                 => 'x1',
        mariadb               => $mariadb,
        innodb_file_per_table => true,
    }
}
