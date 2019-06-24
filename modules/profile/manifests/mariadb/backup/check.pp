# A module that gets installed on the backup metadata database
# And checks backups are being generated regularly and correctly,
# they are "fresh" (last backup isn't too old) and seemingly
# correct. Generate an icinga alert if not.
# Only metadata checks are done- full backup tests are to be
# done on a separate class.
class profile::mariadb::backup::check (
    $dump_dcs          = hiera('profile::mariadb::backup::check::dump::datacenters', ),
    $dump_sections     = hiera('profile::mariadb::backup::check::dump::sections', ),
    $snapshot_dcs      = hiera('profile::mariadb::backup::check::snapshot::datacenters', ),
    $snapshot_sections = hiera('profile::mariadb::backup::check::snapshot::sections', ),
) {
    class { 'mariadb::monitor_backup_script': }

    $dump_dcs.each |String $datacenter| {
        $dump_sections.each |String $section| {
            mariadb::monitor_backup { "${datacenter}-${section}-dump":
                section    => $section,
                datacenter => $datacenter,
                type       => 'dump',
                freshness  => 691200,  # 8 days
            }
        }
    }
    $snapshot_dcs.each |String $datacenter| {
        $snapshot_sections.each |String $section| {
            mariadb::monitor_backup { "${datacenter}-${section}-snapshot":
                section    => $section,
                datacenter => $datacenter,
                type       => 'snapshot',
                freshness  => 345600,  # 4 days
            }
        }
    }
}

