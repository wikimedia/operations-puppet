class role::mediawiki::maintenance {
    include ::profile::standard
    include ::profile::base::firewall

    # MediaWiki
    include ::role::mediawiki::common
    include ::profile::mediawiki::maintenance

    # MariaDB
    include ::profile::mariadb::maintenance
    include ::profile::mariadb::client

    # NOC - https://noc.wikimedia.org/
    include ::role::noc::site
    include ::profile::tlsproxy::envoy # TLS termination

    # LDAP
    include ::profile::openldap::management
}
