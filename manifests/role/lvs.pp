# role/lvs.pp

@monitoring::group { "lvs": description => "LVS" }
@monitoring::group { "lvs_eqiad": description => "eqiad LVS servers" }
@monitoring::group { "lvs_codfw": description => "codfw LVS servers" }
@monitoring::group { "lvs_ulsfo": description => "ulsfo LVS servers" }
@monitoring::group { "lvs_esams": description => "esams LVS servers" }

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
            $sip['api'][$::site],
            $sip['rendering'][$::site],
            $sip['swift'][$::site],
            $sip['parsoid'][$::site],
            $sip['mathoid'][$::site],
            $sip['citoid'][$::site],
            $sip['cxserver'][$::site],
            $sip['search'][$::site],
            $sip['restbase'][$::site],
            $sip['zotero'][$::site],
            ],

        # codfw (should mirror eqiad above, eventually, and become merged with it via regex
        /^(lvs200[14])$/ => [
            $sip['text'][$::site],
            $sip['bits'][$::site],
            ],
        /^(lvs200[25])$/ => [
            $sip['dns_rec'][$::site],
            ],
        /^(lvs200[36])$/ => [
            $sip['apaches'][$::site],
            $sip['api'][$::site],
            $sip['rendering'][$::site],
            $sip['swift'][$::site],
            ],

        # esams + ulsfo
        /^(lvs[34]00[13])$/ => [
            $sip['text'][$::site],
            $sip['bits'][$::site],
            $sip['mobile'][$::site],
            ],
        /^(lvs300[24])$/ => [
            $sip['upload'][$::site],
            $sip['dns_rec'][$::site],
            ],
        /^(lvs400[24])$/ => [
            $sip['upload'][$::site],
            ],
    }

    include standard

    class { "::lvs::balancer":
        service_ips          => $lvs_balancer_ips,
        lvs_services         => $lvs::configuration::lvs_services,
        lvs_class_hosts      => $lvs::configuration::lvs_class_hosts,
        pybal_global_options => $lvs::configuration::pybal,
        site                 => $::site
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
