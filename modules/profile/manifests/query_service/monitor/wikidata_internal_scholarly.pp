# SPDX-License-Identifier: Apache-2.0
class profile::query_service::monitor::wikidata_internal_scholarly {

    profile::query_service::monitor::sparql_endpoint {
        default:
          server_name => 'wdqs-internal-scholarly.discovery.wmnet';
        'wdqs_internal_scholarly_sre':
          team        => 'data-platform';
        'wdqs_internal_scholarly_search':
          team        => 'search-platform',
    }
}
