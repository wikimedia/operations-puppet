class role::mediawiki_maintenance {
    include ::standard
    include ::profile::base::firewall

    # Mediawiki
    include ::role::mediawiki::common
    include ::profile::mediawiki::maintenance

    # MariaDB (Tendril)
    include ::profile::mariadb::maintenance

    # NOC - https://noc.wikimedia.org/
    include ::role::noc::site

    # LDAP
    include ::role::openldap::management
    include ::ldap::role::client::labs
}
