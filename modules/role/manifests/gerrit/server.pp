# modules/role/manifests/gerrit/production.pp
class role::gerrit::server($host) {
        system::role { 'role::gerrit::server': description => 'Gerrit server' }
        include role::backup::host
        include base::firewall

        sslcert::certificate { $host: }

        monitoring::service { 'https':
            description   => 'HTTPS',
            check_command => "check_ssl_http!${host}",
        }

        backup::set { 'var-lib-gerrit2-review_site-git': }

        gerrit_service_ip_v4 = hiera('serviceip_v4', '127.0.0.1')
        gerrit_service_ip_v6 = hiera('serviceip_v6', '0:0:0:0:0:0:0:1')

        interface::ip { 'role::gerrit::server_ipv4':
            interface => 'eth0',
            address   => $gerrit_service_ip_v4,
            prefixlen => '32',
        }
        interface::ip { 'role::gerrit::server_ipv6':
            interface => 'eth0',
            address   => $gerrit_service_ip_v6,
            prefixlen => '128',
        }

        ferm::service { 'gerrit_ssh':
            proto => 'tcp',
            port  => '29418',
        }

        ferm::service { 'gerrit_http':
            proto => 'tcp',
            port  => 'http',
        }

        ferm::service { 'gerrit_https':
            proto => 'tcp',
            port  => 'https',
        }

        class { '::gerrit':
            host => $host,
        }
}
