# = Class: icinga::monitor::wikidata
#
# Monitor wikidata dispatch lag
class icinga::monitor::wikidata {
    @monitoring::host { 'www.wikidata.org':
        host_fqdn => 'www.wikidata.org',
    }

    monitoring::service { 'wikidata.org dispatch lag':
        description    => 'wikidata.org dispatch lag is higher than 600s',
        check_command  => 'check_wikidata',
        host           => 'www.wikidata.org',
        check_interval => 5,
        retry_interval => 1,
        contact_group  => 'admins,wikidata',
        notes_url      => 'https://phabricator.wikimedia.org/project/view/71/',
    }

    monitoring::service { 'wikidata.org dispatch extreme lag':
        description    => 'wikidata.org dispatch lag is REALLY high (>=4000s)',
        check_command  => 'check_wikidata_crit',
        host           => 'www.wikidata.org',
        check_interval => 5,
        retry_interval => 1,
        contact_group  => 'admins,wikidata',
        notes_url      => 'https://phabricator.wikimedia.org/project/view/71/',
    }

    @monitoring::host { 'test.wikidata.org':
        host_fqdn => 'test.wikidata.org',
    }

    monitoring::service { 'test.wikidata.org dispatch extreme lag':
        description    => 'test.wikidata.org dispatch lag is REALLY high (>=4000s)',
        check_command  => 'check_wikidata_crit',
        host           => 'test.wikidata.org',
        check_interval => 5,
        retry_interval => 1,
        contact_group  => 'admins,wikidata',
        notes_url      => 'https://phabricator.wikimedia.org/project/view/71/',
    }

    monitoring::grafana_alert { 'wikidata-alerts':
        dashboard_uid => 'TUJ0V-0Zk',
        contact_group => 'wikidata',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/WMDE/Wikidata/Alerts',
    }
}
