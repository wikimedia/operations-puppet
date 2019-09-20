# A class to setup the corp OIT LDAP mirror. This is used for cheap recipient
# verification during email accept
# vim: set ts=4 et sw=4:
class role::openldap::corp {
    include ::profile::standard
    include ::profile::backup::host
    include ::profile::base::firewall
    include ::profile::openldap_corp

    system::role { 'openldap::corp':
        description => 'Corp OIT openldap Mirror server'
    }
}
