class role::lvs::balancer {
    system::role { 'role::lvs::balancer': description => 'LVS balancer' }

    $rp_args = inline_template('<%= @interfaces.split(",").map{|x| "net.ipv4.conf.#{x.gsub("_","/")}.rp_filter=0" if !x.start_with?("lo") }.compact.join(",") %>')
    nrpe::monitor_service { 'check_rp_filter_disabled':
        description  => 'Check rp_filter disabled',
        nrpe_command => "/usr/lib/nagios/plugins/check_sysctl ${rp_args}",
    }

    include lvs::configuration
    $sip = $lvs::configuration::service_ips

    $lvs_balancer_ips = $::hostname ? {
        # eqiad
        /^(lvs10(0[14]|07|10))$/ => [ # IPs must be high-traffic1 subnet
            $sip['text'][$::site],
            ],
        /^(lvs10(0[25]|08|11))$/ => [ # IPs must be high-traffic2 subnet
            $sip['upload'][$::site],
            $sip['maps'][$::site],
            $sip['dns_rec'][$::site],
            $sip['misc_web'][$::site],
            $sip['git-ssh'][$::site],
            ],
        /^(lvs10(0[36]|09|12))$/ => [ # IPs must be low-traffic subnet
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
            ],

        # codfw (should mirror eqiad above, eventually, and become merged with it via regex
        /^(lvs200[14])$/ => [ # IPs must be high-traffic1 subnet
            $sip['text'][$::site],
            ],
        /^(lvs200[25])$/ => [ # IPs must be high-traffic2 subnet
            $sip['upload'][$::site],
            $sip['maps'][$::site],
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
            ],

        # esams + ulsfo
        /^(lvs[34]00[13])$/ => [ # IPs must be high-traffic1 subnet
            $sip['text'][$::site],
            ],
        /^(lvs300[24])$/ => [ # IPs must be high-traffic2 subnet
            $sip['upload'][$::site],
            $sip['maps'][$::site],
            $sip['misc_web'][$::site],
            $sip['dns_rec'][$::site],
            ],
        /^(lvs400[24])$/ => [ # IPs must be high-traffic2 subnet
            $sip['upload'][$::site],
            $sip['maps'][$::site],
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

    # temporary experimental component used here as it includes a newer Linux kernel
    if $::operatingsystem == 'Debian' {
        apt::repository { 'wikimedia-experimental':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'experimental',
        }
    }

    class { '::lvs::balancer':
        service_ips          => $lvs_balancer_ips,
        lvs_services         => $lvs::configuration::lvs_services,
        lvs_class_hosts      => $lvs::configuration::lvs_class_hosts,
        pybal_global_options => $lvs::configuration::pybal,
        site                 => $::site
    }

    if os_version('Debian >= jessie') {
        include ::pybal::monitoring
    }

    if $::site in ['eqiad', 'codfw'] {
        include ::lvs::balancer::runcommand
    }

    # production-only tweaks
    if $::realm == 'production' {
        include base::no_nfs_client
        # Bump min_free_kbytes a bit to ensure network buffers are available quickly
        vm::min_free_kbytes { 'lvs':
            pct => 3,
            min => 131072,
            max => 524288,
        }
    }
}
