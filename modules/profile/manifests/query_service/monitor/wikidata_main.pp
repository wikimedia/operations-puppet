# SPDX-License-Identifier: Apache-2.0
# Creates monitoring checks for
class profile::query_service::monitor::wikidata_main {
    profile::query_service::monitor::sparql_endpoint {
        default:
            server_name => 'query-main.wikidata.org';
        'wdqs_main_external_sre':
            team        => 'data-platform';
        'wdqs_main_external_search':
            team        => 'search-platform',
    }
}
