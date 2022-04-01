# Writable LDAP servers (based on OpenLDAP)

class role::openldap::rw {
    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::backup::host
    include ::profile::prometheus::openldap_exporter

    include ::profile::openldap

    system::role { 'openldap::rw':
        description => 'Writable LDAP servers (based on OpenLDAP)'
    }
}
