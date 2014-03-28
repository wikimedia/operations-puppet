
class mariadb::monitor_disk(
    $is_critical   = true,
    $contact_group = 'dba',
    $pct_warning   = 10,
    $pct_critical  = 5,
    ) {
    nrpe::monitor_service { 'mariadb_disk_space':
        description   => 'MariaDB disk space',
        nrpe_command  => "/usr/lib/nagios/plugins/check_disk -w ${pct_warning}% -c ${pct_critical}% -l -e",
        critical      => $is_critical,
        contact_group => $contact_group,
    }
}