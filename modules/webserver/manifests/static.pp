# Installs a generic, static web server (lighttpd)
# with default config, which serves /var/www
class webserver::static {
    include webserver::sysctl_settings
    include firewall

    #TODO: declare this class as incompatible with the other webserver classes.

    package { 'lighttpd':
        ensure => 'present',
    }

    $hasstatus = $::lsbdistcodename ? {
        'hardy' => false,
        default => true,
    }

    service { 'lighttpd':
        ensure    => 'running',
        hasstatus => $hasstatus,
    }

    # Monitoring
    monitor_service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
    }

    # Firewall
    firewall::open_port { "http-${::hostname}":
        port => 80,
    }

    firewall::open_port { "https-${::hostname}":
        port => 443,
    }
}
