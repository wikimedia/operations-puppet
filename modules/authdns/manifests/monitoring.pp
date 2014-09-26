# == Class authdns::monitoring
# Monitoring checks for authdns, specific to Wikimedia setup
#
class authdns::monitoring {
    Class['authdns'] -> Class['authdns::monitoring']

XXX this is borked, because the IPs are shared now.
XXX breaking the syntax with this comment should keep
XXX anyone from merging this until it's sorted out
XXX
XXX probably what we're shooting for is a per-host
XXX monitor for check_dns on the $::fqdn, and then
XXX an additional monitor per public listen addr,
XXX defined once globally.

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
