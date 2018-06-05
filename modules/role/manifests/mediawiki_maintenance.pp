class role::mediawiki_maintenance {
    include ::standard
    include ::base::firewall

    # Mediawiki
    include ::role::mediawiki::common
    include ::profile::mediawiki::maintenance

    # NOC - https://noc.wikimedia.org/
    include ::role::noc::site

    # LDAP
    include ::profile::openldap::management
}
