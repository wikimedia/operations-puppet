# = Class: shinken::shinkengen
#
# Sets up shinkengen python package to generate hosts & services
# config for Shinken by hittig the wikitech API
class shinken::shinkengen {
    include shinken

    package { [
        'python3-yaml',
        'python3-requests',
    ]:
        ensure => present,
    }

    $novaconfig = hiera_hash('novaconfig', {})
    $observer_pass = $novaconfig['observer_password']
    include ::openstack::clientlib

    if $::openstack::version == 'liberty' {
        fail('openstack::verison must be set to Mitaka or later for python3 dependencies.')
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
        require => Package['python3-yaml'],
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
