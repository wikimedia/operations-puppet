# LDAP servers for labs (based on OpenLDAP)

class role::openldap::replica {
    include profile::base::production
    include profile::firewall
    include profile::openldap
    include profile::lvs::realserver
}
