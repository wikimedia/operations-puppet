# = Class: shinken::shinkengen
#
# Sets up shinkengen python package to generate hosts & services
# config for Shinken by hittig the wikitech API
class shinken::shinkengen(
    $site,
    $keystone_host,
    $keystone_port,
    $puppet_enc_host,
) {
    include shinken

    require_package('python-requests',
                    'python-yaml')

    file { '/etc/shinkengen.yaml':
        content => template('shinken/shinkengen.yaml.erb'),
        owner   => 'shinken',
        group   => 'shinken',
    }

    file { '/usr/local/bin/shinkengen':
        source  => 'puppet:///modules/shinken/shinkengen.py',
        owner   => 'shinken',
        group   => 'shinken',
        mode    => '0555',
        require => Package['python-yaml'],
    }

    exec { '/usr/local/bin/shinkengen':
        user    => 'shinken',
        group   => 'shinken',
        unless  => '/usr/local/bin/shinkengen --test-if-up-to-date',
        require => [
            File['/usr/local/bin/shinkengen'],
            File['/etc/shinkengen.yaml'],
            Package['shinken'],
        ],
        notify  => Service['shinken'],
    }
}
