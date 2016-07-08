# modules/role/manifests/gerrit/production.pp
class role::gerrit::server(
        $host = undef,
        $ipv4 = undef,
        $ipv6 = undef,
        $sslhost = $::role::gerrit::server::host,
        ) {

        system::role { 'role::gerrit::server': description => 'Gerrit server' }
        include role::backup::host
        include base::firewall

        if $host == undef or $ipv4 == undef or $ipv6 == undef {
            fail('role::gerrit::server must have $host $ipv4 and $ipv6 provided')
        }

        sslcert::certificate { $sslhost: }

        monitoring::service { 'https':
            description   => 'HTTPS',
            check_command => "check_ssl_http!${host}",
        }

        backup::set { 'var-lib-gerrit2-review_site-git': }

        interface::ip { 'role::gerrit::server_ipv4':
            interface => 'eth0',
            address   => $ipv4,
            prefixlen => '32',
        }
        interface::ip { 'role::gerrit::server_ipv6':
            interface => 'eth0',
            address   => $ipv6,
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
            host    => $host,
            sslhost => $sslhost,
        }
}
