# Checks the metadata database backups of a particular section, datacenter
# and type, and sets up an icinga alert about it
define mariadb::monitor_backup (
    $section,
    $datacenter,
    $type       = 'dump',
    $freshness  = 691200,  # 8 days
) {

    $check_command = "/usr/local/bin/check_mariadb_backups.py --section='${section}' --datacenter='${datacenter}' \
--type='${type}' --freshness='${freshness}'"

    nrpe::monitor_service { "mariadb_${type}_${section}_${datacenter}":
        description    => "${type} of ${section} in ${datacenter}",
        nrpe_command   => $check_command,
        critical       => false,
        contact_group  => 'admins',
        check_interval => 30,  # Don't check too often
        require        => File['/usr/local/bin/check_mariadb_backups.py'],
        notes_url      => 'https://wikitech.wikimedia.org/wiki/MariaDB/Backups',
    }
}
