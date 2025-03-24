# SPDX-License-Identifier: Apache-2.0
# Creates monitoring checks for
class profile::query_service::monitor::wikidata_scholarly {
    profile::query_service::monitor::sparql_endpoint {
        default:
          server_name => 'query-scholarly.wikidata.org';
        'wdqs_scholarly_external_sre':
          team        => 'data-platform';
        'wdqs_scholarly_external_search':
          team        => 'search-platform',
    }
}
