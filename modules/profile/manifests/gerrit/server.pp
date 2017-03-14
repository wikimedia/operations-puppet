# modules/profile/manifests/gerrit/server.pp
#
# filtertags: labs-project-git labs-project-ci-staging
class profile::gerrit::server(
    $ipv4 = hiera('profile::gerrit::server::ipv4'),
    $ipv6 = hiera('profile::gerrit::server::ipv6'),
    $bacula = hiera('profile::gerrit::server::bacula')
) {

    system::role { 'role::gerrit::server': description => 'Gerrit server' }

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

    monitoring::service { 'gerrit_ssh':
        description   => 'SSH access',
        check_command => 'check_ssh_port!29418',
        contact_group => 'admins,gerrit',
    }

    if $bacula != undef {
        backup::set { $bacula: }
    }

    include ::base::firewall

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
        host        => 'gerrit.wikimedia.org',
        master_host => 'cobalt.wikimedia.org',
        slave       => true,
    }
}
