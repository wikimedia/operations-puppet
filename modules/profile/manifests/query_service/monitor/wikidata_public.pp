# SPDX-License-Identifier: Apache-2.0
# Creates monitoring checks for
class profile::query_service::monitor::wikidata_public {
    profile::query_service::monitor::sparql_endpoint {
        default:
          server_name => 'query.wikidata.org';
        'wdqs_external_sre':
          team        => 'data-platform';
        'wdqs_external_search':
          team        => 'search-platform',
    }
}
