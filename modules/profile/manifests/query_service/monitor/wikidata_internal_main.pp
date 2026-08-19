# SPDX-License-Identifier: Apache-2.0
class profile::query_service::monitor::wikidata_internal_main {

    profile::query_service::monitor::sparql_endpoint {
        default:
          server_name => 'wdqs-internal-main.discovery.wmnet';
        'wdqs_internal_main_sre':
          team        => 'data-platform';
        'wdqs_internal_main_search':
          team        => 'search-platform',
    }
}
