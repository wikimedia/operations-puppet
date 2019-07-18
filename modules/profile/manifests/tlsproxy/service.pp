class profile::tlsproxy::service(
    String $servicename = lookup('profile::tlsproxy::service::name'),
    Array[Stdlib::Port] $upstream_ports = lookup('profile::tlsproxy::service::upstream_ports'),
    String $ocsp_proxy = lookup('http_proxy'),
    String $check_command = lookup('profile::tlsproxy::service::check_command'),
    String $notes_url = lookup('profile::tlsproxy::service::notes_url'),
) {
    tlsproxy::localssl { $servicename:
        server_name    => $servicename,
        certs          => [$servicename],
        upstream_ports => $upstream_ports,
        default_server => true,
        ocsp_proxy     => $ocsp_proxy,
    }

    monitoring::service { "${servicename}-https":
        description   => "${servicename} HTTPS",
        check_command => $check_command,
        notes_url     => $notes_url,
    }

    ferm::service { "${servicename}-proxy-https":
        proto   => 'tcp',
        notrack => true,
        port    => '443',
    }
}
