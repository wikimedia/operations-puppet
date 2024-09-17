# SPDX-License-Identifier: Apache-2.0
# Monitor external blazegraph (categories) settings
class profile::query_service::monitor::categories {
    ensure_packages('python3-requests')
    file { '/usr/lib/nagios/plugins/check_categories.py':
        ensure => absent,
    }

    nrpe::plugin { 'check_categories.py':
        source => 'puppet:///modules/query_service/nagios/check_categories.py',
    }

    nrpe::monitor_service { 'Categories_Lag':
        description    => 'Categories update lag',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_categories.py --lag',
        check_interval => 720, # every 6 hours
        retry_interval => 60,  # retry after 1 hour
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service/Runbook#Categories_update_lag',
    }

}
