# modules/role/manifests/gerrit/production.pp
class role::gerrit::production($host) {
        system::role { 'role::gerrit::production': description => 'Gerrit master' }
        include role::backup::host
        include base::firewall

        sslcert::certificate { $host: }

        monitoring::service { 'https':
            description   => 'HTTPS',
            check_command => "check_ssl_http!${host}",
        }

        backup::set { 'var-lib-gerrit2-review_site-git': }

        interface::ip { 'role::gerrit::production_ipv4':
            interface => 'eth0',
            address   => '208.80.154.81',
            prefixlen => '32',
        }
        interface::ip { 'role::gerrit::production_ipv6':
            interface => 'eth0',
            address   => '2620:0:861:3:208:80:154:81',
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
