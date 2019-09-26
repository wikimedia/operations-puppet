# Monitor external blazegraph (categories) settings
class query_service::monitor::categories {
    require_package('python3-requests')
    file { '/usr/lib/nagios/plugins/check_categories.py':
        source => 'puppet:///modules/query_service/nagios/check_categories.py',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    # categories are updated weekly, this is a low frequency check
    nrpe::monitor_service { 'Categories_Ping':
        description    => 'Categories endpoint',
        nrpe_command   => '/usr/lib/nagios/plugins/check_categories.py --ping',
        check_interval => 720, # every 6 hours
        retry_interval => 60,  # retry after 1 hour
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service',
    }

    nrpe::monitor_service { 'Categories_Lag':
        description    => 'Categories update lag',
        nrpe_command   => '/usr/lib/nagios/plugins/check_categories.py --lag',
        check_interval => 720, # every 6 hours
        retry_interval => 60,  # retry after 1 hour
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service',
    }

}
