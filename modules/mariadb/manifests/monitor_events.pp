# SPDX-License-Identifier: Apache-2.0
# Check that all events in the ops database are ENABLED
# These are the query killers.
# Alert if any event is found in a non-ENABLED state

define mariadb::monitor_events(
    $socket        = '/run/mysqld/mysqld.sock',
    $is_critical   = false,
    $contact_group = 'admins',
) {

    nrpe::plugin { 'check_mariadb_events':
        source => 'puppet:///modules/mariadb/check_mariadb_events.sh',
    }

    $check_command = "/usr/local/lib/nagios/plugins/check_mariadb_events ${socket}"

    nrpe::monitor_service { "mariadb_events_${name}":
        description   => "MariaDB Events ${name}",
        nrpe_command  => $check_command,
        critical      => $is_critical,
        contact_group => $contact_group,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/MariaDB/troubleshooting#Event_Scheduler',
    }
}
