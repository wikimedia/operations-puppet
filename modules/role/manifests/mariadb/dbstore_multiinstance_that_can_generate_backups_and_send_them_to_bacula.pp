class role::mariadb::dbstore_multiinstance_that_can_generate_backups_and_send_them_to_bacula {
    system::role { 'mariadb::core':
        description => 'DBStore multi-instance server that can generate backups and send them to bacula',
    }

    include ::standard
    include ::profile::base::firewall
    include ::profile::backup::host
    include ::profile::mariadb::dbstore_multiinstance
    include ::profile::mariadb::backup::mydumper
    include ::profile::mariadb::backup::bacula
}
