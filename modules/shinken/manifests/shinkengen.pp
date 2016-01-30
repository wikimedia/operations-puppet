# = Class: shinken::shinkengen
#
# Sets up shinkengen python package to generate hosts & services
# config for Shinken by hittig the wikitech API
#
# = Parameters
#
# [*ldap_server*]
#   LDAP server to use to grab information about hosts from
#
# [*ldap_bindas*]
#   What to bind as when connecting to LDAP server
class shinken::shinkengen(
    $ldap_server = 'ldap-labs.eqiad.wikimedia.org',
    $ldap_bindas = 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
){

    include shinken
    include passwords::ldap::labs
    $ldap_pass = $passwords::ldap::labs::proxypass

    package { [
        'python3-ldap3', # Custom package of https://pypi.python.org/pypi/python3-ldap
        'python3-yaml',
        'python3-jinja2',
    ]:
        ensure => present,
    }

    file { '/etc/shinkengen.yaml':
        content => template('shinken/shinkengen.yaml.erb'),
        owner   => 'shinken',
        group   => 'shinken',
    }

    file { '/usr/local/bin/shinkengen':
        source  => 'puppet:///modules/shinken/shinkengen',
        owner   => 'shinken',
        group   => 'shinken',
        mode    => '0555',
        require => Package['python3-ldap3', 'python3-yaml', 'python3-jinja2'],
    }

    exec { '/usr/local/bin/shinkengen':
        user    => 'shinken',
        group   => 'shinken',
        unless  => '/usr/local/bin/shinkengen --test-if-up-to-date',
        require => [
            File['/usr/local/bin/shinkengen'],
            File['/etc/shinkengen.yaml']
        ],
        notify  => Service['shinken'],
    }
}
