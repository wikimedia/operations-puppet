# LDAP servers for labs (based on OpenLDAP)

class role::openldap::replica {
    include ::standard
    include ::profile::base::firewall
    include ::profile::prometheus::openldap_exporter

    include ::profile::openldap

    system::role { 'openldap::labs':
        description => 'LDAP read-only replica'
    }
}
