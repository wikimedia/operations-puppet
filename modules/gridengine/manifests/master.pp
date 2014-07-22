# gridengine/master.pp

class gridengine::master {
    class { 'gridengine':
        gridmaster => $fqdn,
    }

    package { 'gridengine-master':
        ensure  => latest,
        require => Package['gridengine-common'],
    }

    class monitoring {
        package { 'gridengine-client':
            ensure => latest,
        }

        file { '/usr/local/sbin/grid-ganglia-report':
            ensure  => present,
            mode    => '0555',
            source  => 'puppet:///modules/gridengine/grid-ganglia-report',
            require => [Package['gridengine-client'], Package['libxml-libxml-perl']],
        }

        cron { 'grid-ganglia-report':
            ensure  => present,
            command => '/usr/local/sbin/grid-ganglia-report',
            user    => 'root',
            require => File['/usr/local/sbin/grid-ganglia-report'],
        }
    }

    include monitoring
}
