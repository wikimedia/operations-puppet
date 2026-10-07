class dumps::web::cleanup(
    $miscdumpsdir = undef,
    $xmldumpsdir = undef,
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
    }

    class {'::dumps::web::cleanups::xmldumps':
        xmldumpsdir => $xmldumpsdir,
        user        => $user,
    }
}
