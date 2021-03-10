# a placeholder profile for a manual gitlab setup by
# https://phabricator.wikimedia.org/T274458
class profile::gitlab(
    Stdlib::IP::Address::V4 $service_ip_v4 = lookup('profile::gitlab::service_ip_v4'),
    Stdlib::IP::Address::V6 $service_ip_v6 = lookup('profile::gitlab::service_ip_v6'),
){

    # add a service IP to the NIC - T276148
    interface::alias { 'gitlab service IP':
        ipv4 => $service_ip_v4,
        ipv6 => $service_ip_v6,
    }

    # open ports in firewall - T276144

    # world -> service IP, HTTP
    ferm::service { 'gitlab-http-public':
        proto  => 'tcp',
        port   => 80,
        drange => "${service_ip_v4} ${service_ip_v6}",
    }

    # world -> service IP, HTTPS
    ferm::service { 'gitlab-https-public':
        proto  => 'tcp',
        port   => 443,
        drange => "${service_ip_v4} ${service_ip_v6}",
    }
}
