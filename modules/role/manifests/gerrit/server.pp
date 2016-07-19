# modules/role/manifests/gerrit/production.pp
class role::gerrit::server($ipv4, $ipv6, $bacula = undef) {
        system::role { 'role::gerrit::server': description => 'Gerrit server' }
        include role::backup::host
        include base::firewall

        $host = hiera('gerrit::host')

        if hiera('gerrit::proxy::lets_encrypt') {
            letsencrypt::cert::integrated { 'gerrit':
                subjects   => $host,
                puppet_svc => 'apache2',
                system_svc => 'apache2',
            }
        } else {
            sslcert::certificate { $host: }
        }

        monitoring::service { 'https':
            description   => 'HTTPS',
            check_command => "check_ssl_http!${host}",
            contact_group => 'admins,gerrit',
        }

        monitoring::service { 'gerrit_ssh':
            description   => 'SSH access',
            check_command => 'check_ssh_port!29418',
            contact_group => 'admins,gerrit',
        }

        if $backup != undef {
            backup::set { $bacula: }
        }

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

        class { '::gerrit': }
}
