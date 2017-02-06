class dumps::web::cleanup(
    $miscdumpsdir = undef,
    $isreplica = undef,
    $labscopy = undef,
    $xmldumpsdir = undef,
    $dumpstempdir = undef,
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
        labscopy     => $labscopy,
    }

    class {'::dumps::web::cleanups::xmldumps':
        xmldumpsdir  => $xmldumpsdir,
        dumpstempdir => $dumpstempdir,
        user         => $user,
        isreplica    => $isreplica,
        labscopy     => $labscopy,
    }
}
