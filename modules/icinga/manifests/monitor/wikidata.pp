# = Class: icinga::monitor::wikidata
#
# Monitor wikidata dispatch lag
class icinga::monitor::wikidata {
    @monitoring::host { 'www.wikidata.org':
        host_fqdn => 'www.wikidata.org',
    }

    monitoring::service { 'wikidata.org dispatch lag':
        description    => 'wikidata.org dispatch lag is higher than 300s',
        check_command  => 'check_wikidata',
        host           => 'www.wikidata.org',
        check_interval => 5,
        retry_interval => 1,
        contact_group  => 'admins,wikidata',
    }
}
