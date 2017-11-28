# TODO: Revisit the is_critical part. We probably want pages for DB problems for
# at least a group of people
# TODO: Drop this check and use the common check_disk, with the newly added
# parameters
class mariadb::monitor_disk(
    $is_critical   = true,
    $contact_group = 'dba',
    $pct_warning   = 10,
    $pct_critical  = 5,
    ) {
    nrpe::monitor_service { 'mariadb_disk_space':
        description   => 'MariaDB disk space',
        nrpe_command  => "/usr/lib/nagios/plugins/check_disk \
-w ${pct_warning}% -c ${pct_critical}% -l -e --exclude-type=tracefs",
        critical      => $is_critical,
        contact_group => $contact_group,
    }
}
