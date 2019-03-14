# Check that the given instance is in the given read-only mode
# Alert if we find the oppsite value
# use it by adding the appropiate section name ('s1', 'm3', etc.)
define mariadb::monitor_readonly(
    $read_only     = 1,
    $port          = 3306,
    $is_critical   = false,
    $contact_group = 'admins',
) {

    $check_command = "/usr/bin/check_mariadb.py --port=${port} --icinga --check_read_only=${read_only} --process"

    nrpe::monitor_service { "mariadb_read_only_${name}":
        description   => "MariaDB read only ${name}",
        nrpe_command  => $check_command,
        critical      => $is_critical,
        contact_group => $contact_group,
        require       => File['/usr/bin/check_mariadb.py'],
        notes_url     => 'https://wikitech.wikimedia.org/wiki/MariaDB/troubleshooting',
    }
}
