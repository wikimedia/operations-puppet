# temp allow rsyncing gerrit data to new server
class profile::gerrit::migration (
    $source_host = lookup(gerrit::server::master_host),
    $data_dir  = lookup(gerrit::server::data_dir),
    $user_name = lookup(gerrit::server::user_name),
) {

    ferm::service { 'gerrit-migration-rsync':
        proto  => 'tcp',
        port   => '873',
        srange => "(@resolve((${source_host})) @resolve((${source_host}), AAAA))",
    }

    # FIXME
    # group { $user_name:
    #     ensure => present,
    # }

    # user { $user_name:
    #     ensure     => 'present',
    #     gid        => $user_name,
    #     shell      => '/bin/bash',
    #     home       => "/var/lib/${user_name}",
    #     system     => true,
    #     managehome => true,
    # }

    # file { $data_dir:
    #     ensure => directory,
    #     owner  => 'gerrit2',
    #     group  => 'gerrit2',
    #     mode   => '0664',
    # }

    class { '::rsync::server': }

    rsync::server::module { 'gerrit-data':
        path        => $data_dir,
        read_only   => 'no',
        hosts_allow => $source_host,
    }

    rsync::server::module { 'gerrit-var-lib':
        path        => '/var/lib/gerrit2/review_site',
        read_only   => 'no',
        hosts_allow => $source_host,
    }

    file { "/srv/home-${source_host}/":
        ensure => 'directory',
    }

    rsync::server::module { 'gerrit-home':
        path        => "/srv/home-${source_host}",
        read_only   => 'no',
        hosts_allow => $source_host,
    }
}
