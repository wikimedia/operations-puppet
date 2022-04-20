# Check that the given instance has the event scheduler enabled
# Alert if we find the oppsite value
# use it by adding the appropiate section name ('s1', 'm3', etc.)
define mariadb::monitor_eventscheduler(
    $event_scheduler     = 1,
    $port          = 3306,
    $is_critical   = false,
    $contact_group = 'admins',
) {

    $check_command = "db-check-health --port=${port} --icinga --check_event_scheduler=${event_scheduler} --process"

    nrpe::monitor_service { "mariadb_event_scheduler_${name}":
        description   => "MariaDB Event Scheduler ${name}",
        nrpe_command  => $check_command,
        critical      => $is_critical,
        contact_group => $contact_group,
        require       => Package['wmfmariadbpy-common'],
        notes_url     => 'https://wikitech.wikimedia.org/wiki/MariaDB/troubleshooting#Event_Scheduler',
    }
}
