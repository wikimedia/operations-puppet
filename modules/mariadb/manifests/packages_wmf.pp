# MariaDB WMF patched build installed in /opt.
# Unless you're setting up a production server,
# you probably want vanilla mariadb::packages

class mariadb::packages_wmf (
    String[1] $package,
) {
    ensure_packages([
        $package,
        'percona-toolkit',
        'grc',
    ])

    ensure_packages('mariadb-backup')

    # Manual override until all hosts are in >10.1.44-1 or >10.4.13-1
    file { '/usr/local/bin/mbstream':
        ensure  => 'link',
        target  => "/opt/${package}/bin/mbstream",
        require => Package[$package]
    }
}
