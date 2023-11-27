# SPDX-License-Identifier: Apache-2.0
# Checks the metadata database backups of a particular section, datacenter
# and type, and sets up an icinga alert about it
define dbbackups::check (
    String $section,
    String $datacenter,
    Stdlib::Unixpath $config_file    = '/etc/wmfbackups/backups_check.ini',
    String $type                     = 'dump',
    Integer[0] $freshness            = 691200,  # 8 days
    Integer[0] $min_size             = 307200,
    Float[0.0] $warn_size_percentage = 5,
    Float[0.0] $crit_size_percentage = 15,
) {
    # Send command without quotes due to surprising sudoers behaviour:
    # https://gerrit.wikimedia.org/r/c/operations/puppet/+/977603/comments/b8d512ac_102df5ba
    $check_command = "/usr/bin/check-mariadb-backups \
--config-file=${config_file} \
--section=${section} --datacenter=${datacenter} \
--type=${type} --freshness=${freshness} --min-size=${min_size} \
--warn-size-percentage=${warn_size_percentage} --crit-size-percentage=${crit_size_percentage}"

    nrpe::monitor_service { "mariadb_${type}_${section}_${datacenter}":
        description    => "${type} of ${section} in ${datacenter}",
        nrpe_command   => $check_command,
        critical       => false,
        contact_group  => 'admins',
        sudo_user      => 'backupcheck',
        check_interval => 30,  # Don't check too often
        require        => [
            Package['wmfbackups-check'],
            File['/etc/wmfbackups/valid_sections.txt'],
            User['backupcheck'],
        ],
        notes_url      => 'https://wikitech.wikimedia.org/wiki/MariaDB/Backups#Rerun_a_failed_backup',
    }
}
