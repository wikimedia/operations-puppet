class dumps::web::cleanup(
    $miscdumpsdir = undef,
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
}
