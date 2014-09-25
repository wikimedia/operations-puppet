# = Class: icinga::monitor::wikidata
#
# Monitor wikidata dispatch lag
class icinga::monitor::wikidata {

    @monitor_host { 'wikidata':
        ip_address => '91.198.174.192',
    }

    monitor_service { 'wikidata.org dispatch lag':
        description   => 'check if wikidata.org dispatch lag is higher than 2 minutes',
        check_command => 'check_wikidata',
        host          => 'wikidata',
        normal_check_interval => 30,
        retry_check_interval => 5,
        contact_group => 'admins,wikidata',
    }
}
