# == class profile::pybal
#
# Configures pybal on a server, lvs or otherwise.
class profile::pybal(
    String $bgp = lookup('profile::pybal::bgp'),
    Boolean $primary = lookup('profile::pybal::primary'),
    String $conftool_prefix = lookup('conftool_prefix'),
    String $config_source = lookup('profile::pybal::config_source'),
    Stdlib::Host $config_host = lookup('profile::pybal::config_host'),
    Hash $wikimedia_clusters = lookup('wikimedia_clusters'),
    Stdlib::Port $etcd_port = lookup('profile::pybal::etcd_port', {'default_value'                    => 2379}),
    Optional[Integer] $override_bgp_med = lookup('profile::pybal::override_bgp_med', {'default_value' => undef}),
    Boolean $ipip_enabled = lookup('profile::pybal::ipip_enabled', {'default_value'                   => false}),
) {
    # Includes all the common configs.
    include profile::lvs::configuration
    $services = wmflib::service::get_services_for_lvs($profile::lvs::configuration::lvs_class, $::site)

    $ipv4_address = ipresolve($::fqdn, 4)

    $bgp_med = $override_bgp_med ? {
        undef   => $primary ? { true => 0, default => 100},
        default => $override_bgp_med,
    }

    $global_options = {
        'bgp' => $bgp,
        'bgp-peer-address' => $::hostname ? {
            /^lvs10[0-9][0-9]$/ => "[ '208.80.154.196', '208.80.154.197' ]", # cr1-eqiad,cr2-eqiad
            /^lvs2011$/         => "[ '10.192.23.1' ]", # lsw1-a2-codfw gateway
            /^lvs2012$/         => "[ '10.192.11.1' ]", # lsw1-b2-codfw gateway
            /^lvs201[3-4]$/     => "[ '208.80.153.192', '208.80.153.193' ]", # cr1-codfw,cr2-codfw
            /^lvs30(08|10)$/    => "[ '10.80.0.1' ]", # asw1-bw27-esams gateway
            /^lvs3009$/         => "[ '10.80.1.1' ]", # asw1-by27-esams gateway
            /^lvs40[0-9][0-9]$/ => "[ '198.35.26.192', '198.35.26.193' ]",   # cr3-ulsfo,cr4-ulsfo
            /^lvs50[0-9][0-9]$/ => "[ '103.102.166.131', '103.102.166.130' ]", # cr3-eqsin,cr2-eqsin
            # Note drmrs is different because it has L3 ToR switches, while the
            # others above are a shared L2 domain across both racks
            /^lvs600[13]$/      => "[ '10.136.0.1' ]", # asw1-b12-drmrs gateway
            /^lvs6002$/         => "[ '10.136.1.1' ]", # asw1-b13-drmrs gateway
            default             => '(unspecified)'
            },
        'bgp-nexthop-ipv4'               => $facts['ipaddress'],
        'bgp-nexthop-ipv6'               => inline_template("<%= require 'ipaddr'; (IPAddr.new(@ipaddress6).mask(64) | IPAddr.new(\"::\" + @ipaddress.gsub('.', ':'))).to_s() %>"),
        'instrumentation'                => 'yes',
        'instrumentation_ips'            => "[ '127.0.0.1', '::1', '${ipv4_address}' ]",
        'advertised_instrumentation_ips' => wmflib::service::get_i13n_ips_for_lvs(),
        'bgp-local-ips'                  => "[ '${ipv4_address}' ]",
        'bgp-med'                        => $bgp_med,
    }

    # Base class, not parametrized
    class { '::pybal': }

    if ($config_source == 'etcd' and $etcd_port != 2379) {
        $pybal_config_host = "${config_host}:${etcd_port}"
    }
    else {
        $pybal_config_host = $config_host
    }
    class { '::pybal::configuration':
        global_options  => $global_options,
        services        => $services,
        lvs_class_hosts => $profile::lvs::configuration::lvs_class_hosts,
        site            => $::site,
        conftool_prefix => $conftool_prefix,
        config          => $config_source,
        config_host     => $pybal_config_host,
        ipip_enabled    => $ipip_enabled,
    }

    class { '::pybal::monitoring':
        config_host   => $config_host,
        config_source => $config_source,
        etcd_port     => $etcd_port,
        services      => $services,
    }

    nrpe::plugin { 'check_pybal_restart':
        source => 'puppet:///modules/profile/monitoring/check_service_restart.py',
    }

    nrpe::monitor_service { 'check_service_restart_pybal':
        description    => 'Check if Pybal has been restarted after pybal.conf was changed',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_pybal_restart --service pybal.service --file /etc/pybal/pybal.conf',
        check_interval => 120, # 120mins
        retry_interval => 60,  # 60mins
        notes_url      => 'https://wikitech.wikimedia.org/wiki/PyBal#Pybal_service_has_not_been_restarted',
    }

    # Sites with MediaWiki appservers need runcommand
    if $::site in keys($wikimedia_clusters['appserver']['sites']) {
        class { '::lvs::balancer::runcommand': }
    }

}
