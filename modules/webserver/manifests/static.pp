# Installs a generic, static web server (lighttpd)
# with default config, which serves /var/www
class webserver::static {
    include webserver::sysctl_settings

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
    monitoring::service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
    }

    # Firewall
    ferm::service { "http-${::hostname}":
        proto => 'tcp',
        port  => 80,
    }

    ferm::service { "https-${::hostname}":
        proto => 'tcp',
        port  => 443,
    }
}
