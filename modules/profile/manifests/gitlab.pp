# a placeholder profile for a manual gitlab setup by
# https://phabricator.wikimedia.org/T274458
class profile::gitlab(
    Stdlib::IP::Address::V4 $service_ip_v4 = lookup('profile::gitlab::service_ip_v4'),
    Stdlib::IP::Address::V6 $service_ip_v6 = lookup('profile::gitlab::service_ip_v6'),
){

    # add secondary (service) IP to NIC
    interface::alias { 'gitlab service IP': # T276148
        ipv4 => $service_ip_v4,
        ipv6 => $service_ip_v6,
    }
}
