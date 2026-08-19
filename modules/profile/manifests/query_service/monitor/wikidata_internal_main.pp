# SPDX-License-Identifier: Apache-2.0
class profile::query_service::monitor::wikidata_internal_main {
    nrpe::monitor_service { 'Query_Service_Internal_Main_HTTP_endpoint':
        ensure         => 'absent',
        description    => 'Internal query service (main) HTTP Port 80',
        nrpe_command   => '/usr/lib/nagios/plugins/check_http -H 127.0.0.1 -p 80 -w 10 -u /readiness-probe',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service',
        migration_task => 'T358029',
    }

    profile::query_service::monitor::sparql_endpoint {
        default:
          server_name => 'wdqs-internal-main.discovery.wmnet';
        'wdqs_internal_main_sre':
          team        => 'data-platform';
        'wdqs_internal_main_search':
          team        => 'search-platform',
    }
}
