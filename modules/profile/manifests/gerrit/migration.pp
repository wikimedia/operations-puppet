# temp allow rsyncing gerrit data to new server
class profile::gerrit::migration (
    $source_host = lookup(gerrit::server::master_host),
    $data_dir  = lookup(gerrit::server::data_dir),
    $user_name = lookup(gerrit::server::user_name),
) {

    $source_ip = ipresolve($source_host, 4)

    ferm::service { 'gerrit-migration-rsync':
        proto  => 'tcp',
        port   => '873',
        srange => "${source_ip}/32",
    }

    group { $user_name:
        ensure => present,
    }

    user { $user_name:
        ensure     => 'present',
        gid        => $user_name,
        shell      => '/bin/bash',
        home       => "/var/lib/${user_name}",
        system     => true,
        managehome => true,
    }

    file { $data_dir:
        ensure => directory,
        owner  => 'gerrit2',
        group  => 'gerrit2',
        mode   => '0664',
    }

    class { '::rsync::server': }

    rsync::server::module { 'gerrit-data':
        path        => $data_dir,
        read_only   => 'no',
        hosts_allow => $source_ip,
    }
}
