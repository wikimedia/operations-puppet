# SPDX-License-Identifier: Apache-2.0
class profile::query_service::monitor::wikidata_internal {
    profile::query_service::monitor::sparql_endpoint {
        default:
            server_name => 'wdqs-internal.discovery.wmnet';
        'wdqs_internal_sre':
            team        => 'data-platform';
        'wdqs_internal_search':
            team        => 'search-platform',
    }
}
