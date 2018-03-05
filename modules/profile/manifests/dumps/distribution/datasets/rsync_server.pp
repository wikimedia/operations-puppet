class profile::dumps::distribution::datasets::rsync_server(
    $rsync_clients = hiera('dumps_web_rsync_server_clients'),
) {
    # By default the resolve() function in ferm performs only an IPv4/A DNS
    # lookup. It fails if a host only has an IPv6 address. Ferm also provides
    # a AAAA lookup mode for IPv6 addresses, but this equally fails if only
    # an IPv4 address is present.

    $rsync_clients_ipv4_ferm = join(concat($rsync_clients['ipv4']['internal'], $rsync_clients['ipv4']['external']), ' ')
    $rsync_clients_ipv6_ferm = join(concat($rsync_clients['ipv6']['internal'], $rsync_clients['ipv6']['external']), ' ')

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
