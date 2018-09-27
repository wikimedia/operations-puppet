# A module that gets installed on the backup metadata database
# And checks backups are being generated regularly and correctly,
# they are "fresh" (last backup isn't too old) and seemingly
# correct. Generate an icinga alert if not.
# Only metadata checks are done- full backup tests are to be
# done on a separate class.
class profile::mariadb::backup::check (
    $datacenters = hiera('profile::mariadb::backup::check::datacenters', ),
    $sections    = hiera('profile::mariadb::backup::check::sections', ),
) {
    require_package(
        'python3-pymysql',  # to connect to the backup metadata db
        'python3-arrow',    # to print human-friendly dates
    )

    file { '/usr/local/bin/check_mariadb_backups.py':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/profile/mariadb/check_mariadb_backups.py',
    }

    $datacenters.each |String $datacenter| {
        $sections.each |String $section| {
            mariadb::monitor_backup { "${datacenter}-${section}":
                section    => $section,
                datacenter => $datacenter,
            }
        }
    }
}

