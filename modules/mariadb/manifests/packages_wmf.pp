# MariaDB WMF patched build installed in /opt.
# Unless you're setting up a production server,
# you probably want vanilla mariadb::packages

class mariadb::packages_wmf (
    String[1] $package,
) {
    stdlib::ensure_packages([
        $package,
        'percona-toolkit',
        'grc',
    ])

    # Manual override until all hosts are in >10.1.44-1 or >10.4.13-1
    file { '/usr/local/bin/mbstream':
        ensure  => 'link',
        target  => "/opt/${package}/bin/mbstream",
        require => Package[$package]
    }

    # Prefer the WMF mariabackup over the distro mariadb-backup package,
    # Everytime we upgrade OS backups will require a manual fix.
    # We may fix this in a different way later on, but for now, unbreak backups upgrades.
    ['mariabackup', 'mariadb-backup'].each |$bin| {
        file { "/usr/local/bin/${bin}":
            ensure  => 'link',
            target  => "/opt/${package}/bin/${bin}",
            require => Package[$package],
        }
    }

    # Never install the distro mariadb-backup alongside the WMF build,
    # so anything pulling it back in fails loudly
    apt::pin { 'mariadb-backup-no-distro':
        package  => 'mariadb-backup',
        pin      => 'release o=Debian',
        priority => -1,
    }
}
