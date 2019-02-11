# == class profile::pybal
#
# Configures pybal on a server, lvs or otherwise.
class profile::pybal(
    $bgp = hiera('profile::pybal::bgp'),
    $primary = hiera('profile::pybal::primary'),
    $conftool_prefix = hiera('conftool_prefix'),
    $config_source = hiera('profile::pybal::config_source'),
    $config_host = hiera('profile::pybal::config_host'),
    $wikimedia_clusters = hiera('wikimedia_clusters'),
    $etcd_port = hiera('profile::pybal::etcd_port', 2379)
) {
    # Includes all the common configs.
    include ::lvs::configuration

    $ipv4_address = ipresolve($::fqdn, 4)

    if $primary {
        $bgp_med = 0
    } else {
        $bgp_med = 100
    }

    # TODO: move bgp-peer-address to a parameter? it will require
    # regex hiera, so maybe not
    $global_options = {
        'bgp' => $bgp,
        'bgp-peer-address' => $::hostname ? {
            /^lvs100[1-2]$/ => '208.80.154.196', # cr1-eqiad
            /^lvs100[4-6]$/ => '208.80.154.197', # cr2-eqiad
            'lvs1016'       => '208.80.154.196', # cr1-eqiad
            /^lvs200[1-3]$/ => '208.80.153.192', # cr1-codfw
            /^lvs200[4-6]$/ => '208.80.153.193', # cr2-codfw
            /^lvs300[12]$/  => '91.198.174.244',  # cr2-esams
            /^lvs300[34]$/  => '91.198.174.245',  # cr1-esams
            /^lvs400[56]$/  => '198.35.26.192',   # cr3-ulsfo
            'lvs4007'       => '198.35.26.193',   # cr4-ulsfo
            /^lvs500[123]$/ => '103.102.166.129', # cr1-eqsin
            default         => '(unspecified)'
            },
        'bgp-nexthop-ipv4'    => $facts['ipaddress'],
        'bgp-nexthop-ipv6'    => inline_template("<%= require 'ipaddr'; (IPAddr.new(@ipaddress6).mask(64) | IPAddr.new(\"::\" + @ipaddress.gsub('.', ':'))).to_s() %>"),
        'instrumentation'     => 'yes',
        'instrumentation_ips' => "[ '127.0.0.1', '::1', '${ipv4_address}' ]",
        'bgp-local-ips'       => "[ '${ipv4_address}' ]",
        'bgp-med'             => $bgp_med,
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
        lvs_services    => $::lvs::configuration::lvs_services,
        lvs_class_hosts => $lvs::configuration::lvs_class_hosts,
        site            => $::site,
        conftool_prefix => $conftool_prefix,
        config          => $config_source,
        config_host     => $pybal_config_host
    }

    class { '::pybal::monitoring':
        config_host     => $config_host,
        config_source   => $config_source,
        etcd_port       => $etcd_port,
        lvs_services    => $::lvs::configuration::lvs_services,
        lvs_class_hosts => $lvs::configuration::lvs_class_hosts,
    }

    # Sites with MediaWiki appservers need runcommand
    if $::site in keys($wikimedia_clusters['appserver']['sites']) {
        class { '::lvs::balancer::runcommand': }
    }

}
