# Setup ferm rules for internal and external clients -
# By default the resolve() function in ferm performs only an IPv4/A DNS
# lookup. It fails if a host only has an IPv6 address. Ferm also provides
# a AAAA lookup mode for IPv6 addresses, but this equally fails if only
# an IPv4 address is present.
class profile::dumps::distribution::ferm(
    $internal_rsync_clients = hiera('dumps_web_rsync_server_clients'),
    $rsync_mirrors = hiera('profile::dumps::distribution::mirrors'),
) {
    $internal_clients_ipv4 = $internal_rsync_clients['ipv4']['internal']
    $internal_clients_ipv6 = $internal_rsync_clients['ipv6']['internal']

    $active_mirrors = $rsync_mirrors.filter |$item| { $item['active'] == 'yes' }
    $ipv4_mirrors = $active_mirrors.reduce([]) |$mirrorlist, $item| { $mirrorlist + $item['ipv4'] }
    $ipv6_mirrors = $active_mirrors.reduce([]) |$mirrorlist, $item| { $mirrorlist + $item['ipv6'] }

    $rsync_clients_ipv4_ferm = join(flatten($internal_clients_ipv4 + $ipv4_mirrors), ' ')
    $rsync_clients_ipv6_ferm = join(flatten($internal_clients_ipv6 + $ipv6_mirrors), ' ')

    ferm::service {'dumps_rsyncd_ipv4':
        port   => '873',
        proto  => 'tcp',
        srange => "@resolve((${rsync_clients_ipv4_ferm}))",
    }

    ferm::service {'dumps_rsyncd_ipv6':
        port   => '873',
        proto  => 'tcp',
        srange => "@resolve((${rsync_clients_ipv6_ferm}),AAAA)",
    }
}
