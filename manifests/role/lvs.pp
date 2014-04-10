# role/lvs.pp

@monitor_group { "lvs": description => "LVS" }

class role::lvs::balancer {
    system::role { "role::lvs::balancer": description => "LVS balancer" }

    $rp_args = inline_template('<%= @interfaces.split(",").map{|x| "net.ipv4.conf.#{x}.rp_filter=0"}.join(",") %>')
    nrpe::monitor_service { 'check_rp_filter_disabled':
        description  => 'Check rp_filter disabled',
        nrpe_command => "/usr/lib/nagios/plugins/check_sysctl ${rp_args}",
    }
    $cluster = "lvs"

    include lvs::configuration
    $sip = $lvs::configuration::lvs_service_ips[$::realm]

    $lvs_balancer_ips = $::hostname ? {
        /^(lvs300[13]|amslvs[13]|lvs100[14]|lvs400[13])$/ => [
            $sip['text'][$::site],
            $sip['bits'][$::site],
            $sip['mobile'][$::site],
            ],
        /^(lvs300[24]|amslvs[24]|lvs400[24])$/ => [
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
