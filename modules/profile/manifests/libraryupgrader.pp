class profile::libraryupgrader (
    Stdlib::Unixpath $base_dir = lookup('profile::libraryupgrader::base_dir'),
) {
    ferm::conf { 'docker-preserve':
        ensure => present,
        prio   => 20,
        source => 'puppet:///modules/libraryupgrader/ferm/docker-preserve.conf',
    }

    class { '::libraryupgrader':
        base_dir => $base_dir,
    }
}
