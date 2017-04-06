# modules/profile/manifests/gerrit/server.pp
#
# filtertags: labs-project-git labs-project-ci-staging
class profile::gerrit::server(
    $ipv4 = hiera('gerrit::server::ipv4'),
    $ipv6 = hiera('gerrit::server::ipv6'),
    $host = hiera('gerrit::server::host'),
    $master_host = hiera('gerrit::server::master_host'),
    $bacula = hiera('gerrit::server::bacula'),
) {

    interface::ip { 'role::gerrit::server_ipv4':
        interface => 'eth0',
        address   => $ipv4,
        prefixlen => '32',
    }

    if $ipv6 != undef {
        interface::ip { 'role::gerrit::server_ipv6':
            interface => 'eth0',
            address   => $ipv6,
            prefixlen => '128',
        }
    }

    # Detect if we're a master or a slave. If we're been given a master host
    # and it's not us, we're not a master. If we are that host, we are
    # (obviously). If we're not given any master, assume we're working by
    # ourselves (safest).
    $slave = $master_host ? {
        $::fqdn => false,
        undef   => false,
        default => true,
    }

    monitoring::service { 'gerrit_ssh':
        description   => 'SSH access',
        check_command => 'check_ssh_port!29418',
        contact_group => 'admins,gerrit',
    }

    include ::base::firewall

    ferm::service { 'gerrit_ssh':
        proto => 'tcp',
        port  => '29418',
    }

    if !$slave {
        ferm::service { 'gerrit_http':
            proto => 'tcp',
            port  => 'http',
        }

        ferm::service { 'gerrit_https':
            proto => 'tcp',
            port  => 'https',
        }
    }

    if $bacula != undef and !$slave {
        backup::set { $bacula: }
    }

    class { '::gerrit':
        host  => $host,
        slave => $slave,
    }
}
