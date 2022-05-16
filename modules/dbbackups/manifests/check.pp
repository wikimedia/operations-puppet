# SPDX-License-Identifier: Apache-2.0
# Checks the metadata database backups of a particular section, datacenter
# and type, and sets up an icinga alert about it
define dbbackups::check (
    $db_host,
    $db_user,
    $db_password,
    $db_database,
    $section,
    $datacenter,
    $type                 = 'dump',
    $freshness            = 691200,  # 8 days
    $min_size             = 307200,
    $warn_size_percentage = 5,
    $crit_size_percentage = 15,
) {
    $check_command = "check-mariadb-backups \
--host='${db_host}' --user='${db_user}' --password='${db_password}' --database='${db_database}' \
--section='${section}' --datacenter='${datacenter}' \
--type='${type}' --freshness='${freshness}' --min-size='${min_size}' \
--warn-size-percentage='${warn_size_percentage}' --crit-size-percentage='${crit_size_percentage}'"

    nrpe::monitor_service { "mariadb_${type}_${section}_${datacenter}":
        description    => "${type} of ${section} in ${datacenter}",
        nrpe_command   => $check_command,
        critical       => false,
        contact_group  => 'admins',
        check_interval => 30,  # Don't check too often
        require        => [ Package['wmfbackups-check'], File['/etc/wmfbackups/valid_sections.txt'] ],
        notes_url      => 'https://wikitech.wikimedia.org/wiki/MariaDB/Backups#Rerun_a_failed_backup',
    }
}
