# Check that a host as enough memory for normal operation
# and does not have a very large memory pressure, which could
# lead to swapping or out of memory kills
# Alert if the used memory (outside of cache) is higher than the
# given percentage

class mariadb::monitor_memory(
    Integer[0, 100] $critical = 95,
    Integer[0, 100] $warning  = 90,
    Boolean $is_critical      = false,
    String $contact_group     = 'admins',
) {
    ensure_packages ('monitoring-plugins-contrib')  # for pmp-check-unix-memory

    $path = '/usr/lib/nagios/plugins'
    $check_command = "${path}/pmp-check-unix-memory -c ${critical} -w ${warning}"

    nrpe::monitor_service { 'mariadb_memory':
        description   => 'MariaDB memory',
        nrpe_command  => $check_command,
        critical      => $is_critical,
        contact_group => $contact_group,
        require       => Package['monitoring-plugins-contrib'],
        notes_url     => 'https://wikitech.wikimedia.org/wiki/MariaDB/troubleshooting',
    }
}
