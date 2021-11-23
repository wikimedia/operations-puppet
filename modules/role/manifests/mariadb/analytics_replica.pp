class role::mariadb::analytics_replica {
    system::role { 'mariadb::analytics_replica':
        description => 'MariaDB server containing replicas of mediawiki databases for analytics & research usage',
    }

    include ::profile::base::production
    include ::profile::base::firewall

    include ::profile::mariadb::dbstore_multiinstance
}
