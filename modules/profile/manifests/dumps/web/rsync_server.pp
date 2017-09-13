class profile::dumps::web::rsync_server(
    $rsync_clients_ipv4 = hiera('profile::dumps::web::rsync_server::clients_ipv4'),
    $rsync_clients_ipv6 = hiera('profile::dumps::web::rsync_server::clients_ipv6'),
) {
    # By default the resolve() function in ferm performs only an IPv4/A DNS
    # lookup. It fails if a host only has an IPv6 address. Ferm also provides
    # a AAAA lookup mode for IPv6 addresses, but this equally fails if only
    # an IPv4 address is present.

    $rsync_clients_ipv4_ferm = join($rsync_clients_ipv4, ' ')
    $rsync_clients_ipv6_ferm = join($rsync_clients_ipv6, ' ')

    ferm::service {'dumps_rsyncd_ipv4':
        port   => '873',
        proto  => 'tcp',
        srange => "@resolve((${rsync_clients__ipv4_ferm}))",
    }

    ferm::service {'dumps_rsyncd_ipv6':
        port   => '873',
        proto  => 'tcp',
        srange => "@resolve((${rsync_clients_ipv6_ferm}),AAAA)",
    }
}
