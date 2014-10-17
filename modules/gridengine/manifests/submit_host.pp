# gridengine/submit_host.pp

class gridengine::submit_host( $collectdir = undef )
{
    package { [ 'jobutils' ]:
        ensure => latest,
    }

    package { 'gridengine-client':
        ensure => latest,
        require => Package['gridengine-common'],
    }

    file { '/var/lib/gridengine/default/common/accounting':
        ensure => link,
        target => '/data/project/.system/accounting',
    }
}

