# LDAP servers for labs (based on OpenLDAP)

class role::openldap::labtest {
    include ::profile::base::production
    include ::profile::base::firewall

    include ::profile::openldap_clouddev

    system::role { 'openldap::labtest':
        description => 'LDAP servers for labs test cluster (based on OpenLDAP)'
    }
}
