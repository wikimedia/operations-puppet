# role/lvs.pp

@monitor_group { "lvs": description => "LVS" }

class role::lvs::balancer {
    system::role { "role::lvs::balancer": description => "LVS balancer" }

    $cluster = "lvs"

    # Older PyBal is very dependent on recursive DNS, to the point where it is a SPOF
    # So we'll have every LVS server run their own recursor
    $nameservers_prefix = [ $::ipaddress ]
    include ::dns::recursor

    include lvs::configuration
    $sip = $lvs::configuration::lvs_service_ips[$::realm]

    $lvs_balancer_ips = $::hostname ? {
        /^(amslvs[13]|lvs100[14]|lvs400[13])$/ => [
            $sip['text'][$::site],
            $sip['bits'][$::site],
            $sip['mobile'][$::site],
            ],
        /^(amslvs[24]|lvs400[24])$/ => [
            $sip['upload'][$::site],
            ],
        /^(lvs100[25])$/ => [
            $sip['upload'][$::site],
            $sip['payments'][$::site],
            $sip['dns_rec'][$::site],
            $sip['osm'][$::site],
            $sip['misc_web'][$::site],
            $sip['parsoidcache'][$::site],
            ],
        /^(lvs100[36])$/ => [
            $sip['apaches'][$::site],
            $sip['api'][$::site],
            $sip['rendering'][$::site],
            $sip['search_pool1'][$::site],
            $sip['search_pool2'][$::site],
            $sip['search_pool3'][$::site],
            $sip['search_pool4'][$::site],
            $sip['search_pool5'][$::site],
            $sip['search_prefix'][$::site],
            $sip['swift'][$::site],
            $sip['parsoid'][$::site],
            $sip['search'][$::site]
            ],
        /^(lvs300[1234])$/ => [], # temporary!
    }

    include base,
        ganglia

    class { "::lvs::balancer":
        service_ips => $lvs_balancer_ips,
        lvs_services => $lvs::configuration::lvs_services,
        lvs_class_hosts => $lvs::configuration::lvs_class_hosts,
        pybal_global_options => $lvs::configuration::pybal,
        site => $::site
    }

    if $::site in ['pmtpa', 'eqiad'] {
        include ::lvs::balancer::runcommand
    }
}
