class profile::libraryupgrader (
    Stdlib::Unixpath $base_dir       = lookup('profile::libraryupgrader::base_dir'),
    Boolean          $enable_workers = lookup('profile::libraryupgrader::enable_workers', {default_value => true}),
) {
    ferm::conf { 'docker-preserve':
        ensure => present,
        prio   => 20,
        source => 'puppet:///modules/libraryupgrader/ferm/docker-preserve.conf',
    }

    class { '::libraryupgrader':
        base_dir       => $base_dir,
        enable_workers => $enable_workers,
    }
}
