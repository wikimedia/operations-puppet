# = Class: shinken::shinkengen
#
# Sets up shinkengen python package to generate hosts & services
# config for Shinken by hittig the wikitech API
#
# FIXME: Also restarts shinkin on each run, even if no config
# files have changed
#
# = Parameters
#
# [*ldap_server*]
#   LDAP server to use to grab information about hosts from
#
# [*ldap_bindas*]
#   What to bind as when connecting to LDAP server
#
# [*ldap_pass*]
#   Simple LDAP password to use when connecting to LDAP server
class shinken::shinkengen(
    $ldap_server = 'ldap-eqiad.wikimedia.org',
    $ldap_bindas = 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
    $ldap_pass = $passwords::ldap::labs::proxypass,
){

    include shinken

    package { 'python3-shinkengen':
        ensure => latest,
    }

    file { '/etc/shinkengen.yaml':
        content => template('shinken/shinkengen.yaml.erb'),
        owner   => 'shinken',
        group   => 'shinken',
    }

    exec { '/usr/bin/shingen':
        user    => 'shinken',
        group   => 'shinken',
        require => [Package['python3-shinkengen'], File['/etc/shinkengen.yaml']],
        notify  => Service['shinken'],
    }
}
