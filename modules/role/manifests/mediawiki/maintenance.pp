class role::mediawiki::maintenance {
    system::role { 'mediawiki::maintenance':
        description => 'MediaWiki maintenance systemd timer job server + noc.wikimedia.org',
    }

    include ::profile::base::production
    include ::profile::base::firewall

    # MediaWiki
    include ::role::mediawiki::common
    include ::profile::mediawiki::maintenance

    # MariaDB
    include ::profile::mariadb::maintenance
    include ::profile::mariadb::client

    # NOC - https://noc.wikimedia.org/
    include ::profile::noc
    include ::profile::tlsproxy::envoy # TLS termination

    # LDAP
    if ($::realm == 'production') {
        include ::profile::openldap::management
    }
}
