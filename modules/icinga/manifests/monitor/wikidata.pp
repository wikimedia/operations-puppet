# = Class: icinga::monitor::wikidata
#
# Monitor wikidata dispatch lag
class icinga::monitor::wikidata {

    @monitoring::host { 'wikidata':
        ip_address => '91.198.174.192',
    }

    monitoring::service { 'wikidata.org dispatch lag':
        description           => 'wikidata.org dispatch lag is higher than 300s',
        check_command         => 'check_wikidata',
        host                  => 'wikidata',
        normal_check_interval => 5,
        retry_check_interval  => 1,
        contact_group         => 'admins,wikidata',
    }
}
