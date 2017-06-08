class role::lvs::balancer {
    system::role { 'role::lvs::balancer': description => 'LVS balancer' }

    $rp_args = inline_template('<%= @interfaces.split(",").map{|x| "net.ipv4.conf.#{x.gsub("_","/")}.rp_filter=0" if !x.start_with?("lo") }.compact.join(",") %>')
    nrpe::monitor_service { 'check_rp_filter_disabled':
        description  => 'Check rp_filter disabled',
        nrpe_command => "/usr/lib/nagios/plugins/check_sysctl ${rp_args}",
    }

    include ::lvs::configuration

    $sip = $lvs::configuration::service_ips

    # This is a temporary refactoring, we should do more to clean up here.
    # The whole point of $lvs_balancer_ips is to set up the current LVS node
    # puppet is executing on, yet we're subbing in $::site after selecting a
    # site-specific hostname, etc.  There's also a great deal of redundancy
    # between information here and in configuration.

    $ips_eqiad_high_traffic1 = [ # IPs must be high-traffic1 subnet
        $sip['text'][$::site],
    ]

    $ips_eqiad_high_traffic2 = [ # IPs must be high-traffic2 subnet
        $sip['upload'][$::site],
        $sip['dns_rec'][$::site],
        $sip['misc_web'][$::site],
        $sip['git-ssh'][$::site],
    ]

    $ips_eqiad_low_traffic = [ # IPs must be low-traffic subnet
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
        $sip['graphoid'][$::site],
        $sip['mobileapps'][$::site],
        $sip['kartotherian'][$::site],
        $sip['aqs'][$::site],
        $sip['eventbus'][$::site],
        $sip['apertium'][$::site],
        $sip['ores'][$::site],
        $sip['thumbor'][$::site],
        $sip['prometheus'][$::site],
        $sip['ocg'][$::site],
        $sip['wdqs'][$::site],
        $sip['kibana'][$::site],
        $sip['eventstreams'][$::site],
        $sip['pdfrender'][$::site],
        $sip['trendingedits'][$::site],
        $sip['kubemaster'][$::site],
        $sip['logstash'][$::site],
    ]

    $lvs_balancer_ips = $::hostname ? {
        # eqiad
        /^lvs100[147]$/ => $ips_eqiad_high_traffic1,
        /^lvs100[258]$/ => $ips_eqiad_high_traffic2,
        /^lvs100[369]$/ => $ips_eqiad_low_traffic,
        'lvs1010'       => array_concat(
            $ips_eqiad_high_traffic1,
            $ips_eqiad_high_traffic2,
            $ips_eqiad_low_traffic
        ),

        # codfw (should mirror eqiad above, eventually, and become merged with it via regex
        /^(lvs200[14])$/ => [ # IPs must be high-traffic1 subnet
            $sip['text'][$::site],
            ],
        /^(lvs200[25])$/ => [ # IPs must be high-traffic2 subnet
            $sip['upload'][$::site],
            $sip['misc_web'][$::site],
            $sip['dns_rec'][$::site],
            ],
        /^(lvs200[36])$/ => [ # IPs must be low-traffic subnet
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
            $sip['graphoid'][$::site],
            $sip['mobileapps'][$::site],
            $sip['apertium'][$::site],
            $sip['kartotherian'][$::site],
            $sip['eventbus'][$::site],
            $sip['ores'][$::site],
            $sip['thumbor'][$::site],
            $sip['prometheus'][$::site],
            $sip['wdqs'][$::site],
            $sip['eventstreams'][$::site],
            $sip['pdfrender'][$::site],
            $sip['trendingedits'][$::site],
            $sip['kubemaster'][$::site],
            ],

        # esams + ulsfo
        /^(lvs[34]00[13])$/ => [ # IPs must be high-traffic1 subnet
            $sip['text'][$::site],
            ],
        /^(lvs300[24])$/ => [ # IPs must be high-traffic2 subnet
            $sip['upload'][$::site],
            $sip['misc_web'][$::site],
            $sip['dns_rec'][$::site],
            ],
        /^(lvs400[24])$/ => [ # IPs must be high-traffic2 subnet
            $sip['upload'][$::site],
            $sip['misc_web'][$::site],
            ],
    }

    include ::standard

    salt::grain { 'lvs':
        grain   => 'lvs',
        value   => $lvs::configuration::lvs_grain,
        replace => true,
    }

    salt::grain { 'lvs_class':
        grain   => 'lvs_class',
        value   => $lvs::configuration::lvs_grain_class,
        replace => true,
    }

    # TODO: refactor the whole set of classes
    class { '::lvs::balancer':
        service_ips     => $lvs_balancer_ips,
        lvs_services    => $lvs::configuration::lvs_services,
        lvs_class_hosts => $lvs::configuration::lvs_class_hosts,
        conftool_prefix => hiera('conftool_prefix'),
    }

    include ::profile::pybal

    if $::site in ['eqiad', 'codfw'] {
        include ::lvs::balancer::runcommand
    }

    # production-only tweaks
    if $::realm == 'production' {
        # Bump min_free_kbytes a bit to ensure network buffers are available quickly
        vm::min_free_kbytes { 'lvs':
            pct => 3,
            min => 131072,
            max => 524288,
        }
    }
}
