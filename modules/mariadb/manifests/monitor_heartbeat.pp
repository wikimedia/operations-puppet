# SPDX-License-Identifier: Apache-2.0
# Monitor that pt-heartbeat-wikimedia is running.
# Only for hosts with the master role (db, es, pc)

class mariadb::monitor_heartbeat(
    Boolean $is_critical   = false,
    String  $contact_group = 'admins',
) {
    nrpe::monitor_service { 'pt-heartbeat-wikimedia':
        description   => 'pt-heartbeat-wikimedia process',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1: -a pt-heartbeat-wikimedia',
        critical      => $is_critical,
        contact_group => $contact_group,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/MariaDB/troubleshooting#pt-heartbeat',
    }
}
