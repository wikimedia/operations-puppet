# Class: dnsrecursor
# Parameters:
# - $listen_addresses:
#       Addresses the DNS recursor should listen on for queries
#       (default: [$::ipaddress])
# - $allow_from:
#       Prefixes from which to allow recursive DNS queries
class dnsrecursor(
    $listen_addresses = [$::ipaddress],
    $allow_from       = []
) {
    package { 'pdns-recursor':
        ensure => 'latest',
    }

    system::role { 'dnsrecursor':
        ensure      => 'absent',
        description => 'Recursive DNS server',
    }

    include network::constants

    file { '/etc/powerdns/recursor.conf':
        ensure  => 'present',
        require => Package['pdns-recursor'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('powerdns/recursor.conf.erb'),
    }

    service { 'pdns-recursor':
        ensure    => 'running',
        require   => [Package['pdns-recursor'],
                      File['/etc/powerdns/recursor.conf']
        ],
        subscribe => File['/etc/powerdns/recursor.conf'],
        pattern   => 'pdns_recursor',
        hasstatus => false,
    }

    class metrics {
        # install ganglia metrics reporting on pdns_recursor
        file { '/usr/local/sbin/pdns_gmetric':
            ensure => 'present',
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///files/powerdns/pdns_gmetric',
        }
        cron { 'pdns_gmetric_cron':
            require => File['/usr/local/sbin/pdns_gmetric'],
            command => '/usr/local/sbin/pdns_gmetric',
            user    => 'root',
            minute  => '*',
        }
    }

    define monitor() {
        # Monitoring
        monitoring::host { $title:
            ip_address => $title,
        }
        monitoring::service { "recursive dns ${title}":
            host          => $title,
            description   => 'Recursive DNS',
            check_command => 'check_dns!www.wikipedia.org',
        }
    }

    include metrics
}
