class role::mediawiki::maintenance {
    system::role { 'mediawiki::maintenance':
        description => 'MediaWiki maintenance systemd timer job server',
    }

    include profile::base::production
    include profile::firewall

    # MediaWiki
    include role::mediawiki::common
    include profile::mediawiki::maintenance

    # MariaDB
    include profile::mariadb::maintenance
    include profile::mariadb::client
}
