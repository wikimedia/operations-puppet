# Checks the metadata database backups of a particular section and datacenter,
# and sets up an icinga alert about it
define mariadb::monitor_backup (
    $section,
    $datacenter,
) {

    $check_command = "/usr/local/bin/check_mariadb_backups.py --section='${section}' --datacenter='${datacenter}'"

    nrpe::monitor_service { "mariadb_backup_${section}_${datacenter}":
        description    => "Backup of ${section} in ${datacenter}",
        nrpe_command   => $check_command,
        critical       => false,
        contact_group  => 'admins',
        check_interval => 30,  # Don't check too often
        require        => File['/usr/local/bin/check_mariadb_backups.py'],
        notes_url      => 'https://wikitech.wikimedia.org/wiki/MariaDB/Backups',
    }
}
