# modules/profile/manifests/gerrit/server.pp
#
# filtertags: labs-project-git labs-project-ci-staging
class profile::gerrit::server(
    $ipv4,
    $ipv6 = undef,
    $bacula = undef
) {

    system::role { 'role::gerrit::server': description => 'Gerrit server' }

    monitoring::service { 'gerrit_ssh':
        description   => 'SSH access',
        check_command => 'check_ssh_port!29418',
        contact_group => 'admins,gerrit',
    }

    include ::role::backup::host

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

    class { '::gerrit': }
}
