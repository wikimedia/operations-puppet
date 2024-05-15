# Writable LDAP servers (based on OpenLDAP)

class role::openldap::rw {
    include profile::base::production
    include profile::firewall
    include profile::backup::host
    include profile::openldap
}
