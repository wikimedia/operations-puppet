# == Class profile::openldap::client
#
# This profile installs the OpenLDAP client side tools on a host in production
# and populates /etc/ldap/ldap.conf as needed
#
# By default the readonly replicas are configured in ldap.conf, this can be changed
# with profile::openldap::client::read_write
#
class profile::openldap::client(
    Hash    $ldap_config    = lookup('ldap', Hash, hash, {}),
    Hash    $private_config = lookup('labsldapconfig', {'merge' => hash}),
    Boolean $read_write     = lookup('profile::openldap::client::read_write', {default_value => false}),
){
    if $read_write {
        $servernames = [ $ldap_config['rw-server'], $ldap_config['rw-server-fallback'] ]
    } else {
        $servernames = [ $ldap_config['ro-server'], $ldap_config['ro-server-fallback'] ]
    }

    $ldapconfig = {
        'servernames'          => servernames,
        'basedn'               => $ldap_config['base-dn'],
        'proxyagent'           => $ldap_config['proxyagent'],
        'proxypass'            => $private_config['proxypass'],
        'ca'                   => 'ca-certificates.crt',
    }

    class { 'ldap::client::openldap':
        ldapconfig   => $ldapconfig,
    }
}
