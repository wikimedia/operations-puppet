# LDAP servers for labs (based on OpenLDAP)

class role::openldap::replica {
    include ::profile::base::production
    include ::profile::base::firewall

    if debian::codename::le('buster') {
        include ::profile::prometheus::openldap_exporter
    }

    include ::profile::openldap

    include ::profile::lvs::realserver

    system::role { 'openldap::replica':
        description => 'LDAP read-only replica'
    }
}
