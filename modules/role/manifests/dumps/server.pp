# role classes for dumps.wikimedia.org
class role::dumps::server {
    include ::dumps

    system::role { 'dumps': description => 'dumps.wikimedia.org' }

    monitoring::service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
    }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => 'check_ssl_http!dumps.wikimedia.org',
    }

    # By default the resolve() function in ferm performs only an IPv4/A DNS
    # lookup. It fails if a host only has an IPv6 address. Ferm also provides
    # a AAAA lookup mode for IPv6 addresses, but this equally fails if only
    # an IPv4 address is present.

    $rsync_clients = hiera('dumps::rsync_clients')
    $rsync_clients_ferm = join($rsync_clients, ' ')

    $rsync_clients_ipv6 = hiera('dumps::rsync_clients_ipv6')
    $rsync_clients_ipv6_ferm = join($rsync_clients_ipv6, ' ')

    ferm::service {'dumps_rsyncd_ipv4':
        port   => '873',
        proto  => 'tcp',
        srange => "@resolve((${rsync_clients_ferm}))",
    }

    ferm::service {'dumps_rsyncd_ipv6':
        port   => '873',
        proto  => 'tcp',
        srange => "@resolve((${rsync_clients_ipv6_ferm}),AAAA)",
    }

    ferm::service { 'dumps_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'dumps_https':
        proto => 'tcp',
        port  => '443',
    }

    ferm::service { 'dumps_nfs':
        proto  => 'tcp',
        port   => '2049',
        srange => '$PRODUCTION_NETWORKS',
    }

}
