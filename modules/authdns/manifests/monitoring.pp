# == Class authdns::monitoring
# Monitoring checks for authdns, specific to Wikimedia setup
#
class authdns::monitoring {
    Class['authdns'] -> Class['authdns::monitoring']

    if $authdns::ipaddress {
        $monitor_ip = $authdns::ipaddress
    } else {
        $monitor_ip = $::ipaddress
    }

    monitor_host { $authdns::fqdn:
        ip_address    => $monitor_ip,
    }

    monitor_service { 'auth dns':
        host          => $authdns::fqdn,
        description   => 'Auth DNS',
        check_command => 'check_dns!www.wikipedia.org'
    }
}
