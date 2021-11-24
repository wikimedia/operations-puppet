class role::mariadb::backup_source {
    system::role { 'mariadb::backup_source':
        description => 'MariaDB server containing replicas of mediawiki databases used to generate backups',
    }

    include profile::base::production
    include profile::base::firewall

    include profile::mariadb::dbstore_multiinstance
}
