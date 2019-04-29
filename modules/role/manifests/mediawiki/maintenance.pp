class role::mediawiki::maintenance {
    include ::profile::standard
    include ::profile::base::firewall

    # Mediawiki
    include ::role::mediawiki::common
    include ::profile::mediawiki::maintenance

    # MariaDB
    include ::profile::mariadb::maintenance
    include ::profile::mariadb::client

    # NOC - https://noc.wikimedia.org/
    include ::role::noc::site

    # LDAP
    include ::profile::openldap::management
}
