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

    monitoring::graphite_threshold { 'wikidata.org high edit count':
        description => 'wikidata.org high edit count',
        metric      => "wikidata.rc.edits.total",
        from        => '10min',
        warning     => '600',
        critical    => '800',
        percentage  => '25', # Don't freak out on spikes
    }
}
