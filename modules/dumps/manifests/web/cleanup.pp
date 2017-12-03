class dumps::web::cleanup(
    $miscdumpsdir = undef,
    $isreplica = undef,
    $publicdir = undef,
    $user = undef,
) {
    file { '/etc/dumps':
        ensure => 'directory',
        path   => '/etc/dumps',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { '/etc/dumps/confs':
        ensure => 'directory',
        path   => '/etc/dumps/confs',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    class {'dumps::web::cleanups::miscdumps':
        miscdumpsdir => $miscdumpsdir,
        isreplica    => $isreplica,
    }

    class {'::dumps::web::cleanups::xmldumps':
        publicdir => $publicdir,
        user      => $user,
        isreplica => $isreplica,
    }
}
