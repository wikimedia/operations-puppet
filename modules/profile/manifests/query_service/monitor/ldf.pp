# SPDX-License-Identifier: Apache-2.0
# ldf endpoint monitoring, see T347355.

class profile::query_service::monitor::ldf {
    monitoring::service { 'WDQS_LDF_Endpoint':
        description   => 'WDQS Linked Data Fragments Endpoint',
        check_command => 'check_https_url_for_string!query.wikidata.org!/bigdata/ldf?subject=wd%3AQ42&predicate=wdt%3AP31&object=!wd:Q42  wdt:P31  wd:Q5 .',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service/Runbook',
    }
}
