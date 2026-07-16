# cirrus checks
define icinga::monitor::elasticsearch::cirrus_checks(
    Enum['http', 'https'] $scheme = 'http',
    String $host = $facts['networking']['hostname'],
    Array[Stdlib::Port] $ports = [9200],
    Integer $timeout = 4,
) {
    $ports.each |$port| {
        monitoring::service { "elasticsearch / cirrus frozen writes - ${host}:${port}":
            host           => $host,
            check_command  => "check_cirrus_frozen_writes!${scheme}!${port}!${timeout}",
            description    => "ElasticSearch health check for frozen writes - ${port}",
            critical       => true,
            contact_group  => 'admins,team-discovery',
            notes_url      => 'https://wikitech.wikimedia.org/wiki/Search#Pausing_Indexing',
            migration_task => 'T384998',
        }

        monitoring::service { "elasticsearch / masters eligible - ${host}:${port}":
            host           => $host,
            check_command  => "check_masters_eligible!${scheme}!${port}!${timeout}",
            description    => "ElasticSearch numbers of masters eligible - ${port}",
            critical       => false,
            contact_group  => 'admins,team-discovery',
            notes_url      => 'https://wikitech.wikimedia.org/wiki/Search#Expected_eligible_masters_check_and_alert',
            retries        => 10,  # it is fine if we are missing a master for a short time (during reboots / restarts)
            migration_task => 'T384998',
        }
    }
}
