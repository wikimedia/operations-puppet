# memcached/init.pp

class memcached (
    $memcached_size = '2000',
    $memcached_port = '11000',
    $memcached_ip = '0.0.0.0',
    $version = "present",
    $memcached_options = {},
    $pin=false)
{

    class { "memcached::config":
        memcached_size => "$memcached_size",
        memcached_port => "$memcached_port",
        memcached_ip => "$memcached_ip",
        memcached_options => $memcached_options
    }

    if ( $pin ) {
        apt::pin { 'memcached':
            pin      => 'release o=Ubuntu',
            priority => '1001',
            before   => Package['memcached'],
        }
    }

    package { memcached:
        ensure => $version;
    }

    service { memcached:
        require => Package[memcached],
        enable     => true,
        ensure => running;
    }

    # prefer a direct check if memcached is not running on localhost
    # no point in running this over nrpe for e.g. our memcached cluster
    if ($memcached_ip == '127.0.0.1') {
        nrpe::monitor_service { 'memcached':
            description   => 'Memcached',
            nrpe_command  => "/usr/lib/nagios/plugins/check_tcp -H $memcached_ip -p $memcached_port",
        }
    } else {
        monitor_service { 'memcached':
            description   => 'Memcached',
            check_command => "check_tcp!$memcached_port",
        }
    }

    include ::memcached::ganglia
}

class memcached::disabled {
    service { memcached:
        enable  => false,
        ensure  => stopped;
    }
}
