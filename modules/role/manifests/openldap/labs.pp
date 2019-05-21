# LDAP servers for labs (based on OpenLDAP)

class role::openldap::labs {
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log
    include ::profile::backup::host
    include ::profile::prometheus::openldap_exporter

    include ::profile::openldap

    system::role { 'openldap::labs':
        description => 'LDAP servers for labs (based on OpenLDAP)'
    }
}
