# LDAP servers for labs (based on OpenLDAP)

class role::openldap::labtest {
    include ::standard
    include ::profile::base::firewall
    include ::profile::prometheus::openldap_exporter

    include ::profile::openldap

    system::role { 'openldap::labtest':
        description => 'LDAP servers for labs test cluster (based on OpenLDAP)'
    }
}
