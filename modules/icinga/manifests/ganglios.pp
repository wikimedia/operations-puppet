
class icinga::ganglios {
    include ganglia::collector::config

    package { 'ganglios':
        ensure => 'installed',
    }

    cron { 'ganglios-cron':
        ensure  => present,
        command => 'test -w /var/log/ganglia/ganglia_parser.log && /usr/sbin/ganglia_parser',
        user    => 'icinga',
        minute  => '*/2',
    }

    file { '/var/lib/ganglia/xmlcache':
        ensure => directory,
        mode   => '0755',
        owner  => 'icinga',
    }

}

