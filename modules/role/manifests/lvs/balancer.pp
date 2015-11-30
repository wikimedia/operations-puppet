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
        /^(lvs10(0[14]|07|10))$/ => [
            $sip['text'][$::site],
            $sip['mobile'][$::site],
            ],
        /^(lvs10(0[25]|08|11))$/ => [
            $sip['upload'][$::site],
            $sip['maps'][$::site],
            $sip['dns_rec'][$::site],
            $sip['misc_web'][$::site],
            $sip['parsoidcache'][$::site],
            $sip['stream'][$::site],
            $sip['ocg'][$::site],
            ],
        /^(lvs10(0[36]|09|12))$/ => [
            $sip['apaches'][$::site],
            $sip['api'][$::site],
            $sip['rendering'][$::site],
            $sip['swift'][$::site],
            $sip['parsoid'][$::site],
            $sip['mathoid'][$::site],
            $sip['citoid'][$::site],
            $sip['cxserver'][$::site],
            $sip['search'][$::site],
            $sip['git-ssh'][$::site],
            $sip['restbase'][$::site],
            $sip['zotero'][$::site],
            $sip['graphoid'][$::site],
            $sip['mobileapps'][$::site],
            $sip['aqs'][$::site],
            ],

        # codfw (should mirror eqiad above, eventually, and become merged with it via regex
        /^(lvs200[14])$/ => [
            $sip['text'][$::site],
            $sip['mobile'][$::site],
            ],
        /^(lvs200[25])$/ => [
            $sip['upload'][$::site],
            $sip['misc_web'][$::site],
            $sip['dns_rec'][$::site],
            ],
        /^(lvs200[36])$/ => [
            $sip['apaches'][$::site],
            $sip['api'][$::site],
            $sip['rendering'][$::site],
            $sip['swift'][$::site],
            $sip['search'][$::site],
            $sip['kartotherian'][$::site],
            $sip['restbase'][$::site],
            ],

        # esams + ulsfo
        /^(lvs[34]00[13])$/ => [
            $sip['text'][$::site],
            $sip['mobile'][$::site],
            ],
        /^(lvs300[24])$/ => [
            $sip['upload'][$::site],
            $sip['misc_web'][$::site],
            $sip['dns_rec'][$::site],
            ],
        /^(lvs400[24])$/ => [
            $sip['upload'][$::site],
            $sip['misc_web'][$::site],
            ],
    }

    include standard

    # temporary experimental section used here for newer Linux kernels
    if $::operatingsystem == 'Debian' {
        apt::repository { 'wikimedia-experimental':
            uri         => 'http://apt.wikimedia.org/wikimedia',
            dist        => "${::lsbdistcodename}-wikimedia",
            components  => 'experimental',
        }
    }

    class { '::lvs::balancer':
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
