class role::mediawiki_maintenance {
    include ::standard
    include ::base::firewall

    # Mediawiki
    include ::role::mediawiki::common
    include ::profile::mediawiki::maintenance

    # MariaDB (Tendril)
    include ::profile::mariadb::maintenance

    # NOC - https://noc.wikimedia.org/
    include ::role::noc::site

    # LDAP
    include ::role::openldap::management
    include profile::ldap::client::labs

    # ProxySQL test T175672
    include ::profile::proxysql
    include ::profile::mariadb::client
}
