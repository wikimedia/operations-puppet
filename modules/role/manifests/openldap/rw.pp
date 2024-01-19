# Writable LDAP servers (based on OpenLDAP)

class role::openldap::rw {
    include profile::base::production
    include profile::firewall
    include profile::backup::host

    if debian::codename::le('buster') {
        include profile::prometheus::openldap_exporter
    }

    include profile::openldap
}
