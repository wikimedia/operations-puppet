# role/lvs.pp

@monitor_group { "lvs": description => "LVS" }
@monitor_group { "lvs_pmtpa": description => "pmtpa LVS servers" }
@monitor_group { "lvs_eqiad": description => "eqiad LVS servers" }
@monitor_group { "lvs_codfw": description => "codfw LVS servers" }
@monitor_group { "lvs_ulsfo": description => "ulsfo LVS servers" }
@monitor_group { "lvs_esams": description => "esams LVS servers" }

class role::lvs::balancer {
    system::role { "role::lvs::balancer": description => "LVS balancer" }

    $rp_args = inline_template('<%= @interfaces.split(",").map{|x| "net.ipv4.conf.#{x.gsub("_","/")}.rp_filter=0" if !x.start_with?("lo") }.compact.join(",") %>')
    nrpe::monitor_service { 'check_rp_filter_disabled':
        description  => 'Check rp_filter disabled',
        nrpe_command => "/usr/lib/nagios/plugins/check_sysctl ${rp_args}",
    }

    include lvs::configuration
    $sip = $lvs::configuration::lvs_service_ips[$::realm]

    $lvs_balancer_ips = $::hostname ? {
        # eqiad
        /^(lvs100[14])$/ => [
            $sip['text'][$::site],
            $sip['bits'][$::site],
            $sip['mobile'][$::site],
            ],
        /^(lvs100[25])$/ => [
            $sip['upload'][$::site],
            $sip['dns_rec'][$::site],
            $sip['osm'][$::site],
            $sip['misc_web'][$::site],
            $sip['parsoidcache'][$::site],
            $sip['stream'][$::site],
            $sip['ocg'][$::site],
            ],
        /^(lvs100[36])$/ => [
            $sip['apaches'][$::site],
            $sip['hhvm_appservers'][$::site],
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
            $sip['search'][$::site],
            ],

        # codfw (should mirror eqiad above, eventually, and become merged with it via regex
        /^(lvs200[14])$/ => [
            ],
        /^(lvs200[25])$/ => [
            $sip['dns_rec'][$::site],
            ],
        /^(lvs200[36])$/ => [
            ],

        # esams + ulsfo
        /^(lvs[34]00[13])$/ => [
            $sip['text'][$::site],
            $sip['bits'][$::site],
            $sip['mobile'][$::site],
            ],
        /^(lvs[34]00[24])$/ => [
            $sip['upload'][$::site],
            ],
    }

    include standard

    class { "::lvs::balancer":
        service_ips => $lvs_balancer_ips,
        lvs_services => $lvs::configuration::lvs_services,
        lvs_class_hosts => $lvs::configuration::lvs_class_hosts,
        pybal_global_options => $lvs::configuration::pybal,
        site => $::site
    }

    if $::site in ['eqiad', 'codfw'] {
        include ::lvs::balancer::runcommand
    }

    # Bump min_free_kbytes a bit to ensure network buffers are available quickly
    if $::realm == 'production' {
        vm::min_free_kbytes { 'lvs':
            pct => 3,
            min => 131072,
            max => 524288,
        }
    }
}
