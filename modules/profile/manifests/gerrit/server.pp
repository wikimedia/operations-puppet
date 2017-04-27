# modules/profile/manifests/gerrit/server.pp
#
# filtertags: labs-project-git labs-project-ci-staging
class profile::gerrit::server(
    $ipv4 = hiera('gerrit::server::ipv4'),
    $ipv6 = hiera('gerrit::server::ipv6'),
    $host = hiera('gerrit::server::host'),
    $master_host = hiera('gerrit::server::master_host'),
    $bacula = hiera('gerrit::server::bacula'),
    $gerrit_servers = join(hiera('gerrit::servers'), ' ')
) {

    interface::alias { 'gerrit server':
        ipv4 => $ipv4,
        ipv6 => $ipv6,
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

    # ssh from users to gerrit
    ferm::service { 'gerrit_ssh_users':
        proto => 'tcp',
        port  => '29418',
    }

    # ssh between gerrit servers for cluster support
    ferm::service { 'gerrit_ssh_cluster':
        port   => '22',
        proto  => 'tcp',
        srange => "(@resolve((${gerrit_servers})) @resolve((${gerrit_servers}), AAAA))",
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
