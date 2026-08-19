# SPDX-License-Identifier: Apache-2.0
class profile::query_service::monitor::wikidata_internal_scholarly {
    nrpe::monitor_service { 'Query_Service_Internal_Scholarly_HTTP_endpoint':
        ensure         => 'absent',
        description    => 'Internal query service (scholarly) HTTP Port 80',
        nrpe_command   => '/usr/lib/nagios/plugins/check_http -H 127.0.0.1 -p 80 -w 10 -u /readiness-probe',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service',
        migration_task => 'T358029',

    }
    profile::query_service::monitor::sparql_endpoint {
        default:
          server_name => 'wdqs-internal-scholarly.discovery.wmnet';
        'wdqs_internal_scholarly_sre':
          team        => 'data-platform';
        'wdqs_internal_scholarly_search':
          team        => 'search-platform',
    }
}
