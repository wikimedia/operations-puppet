# SPDX-License-Identifier: Apache-2.0
# [*hcforwarder_config*]
#  Liberica healthcheck forwarder daemon configuration
# [*healthcheck_config*]
#  Liberica healthcheck daemon configuration
# [*fp_config*]
#  Liberica forwarding plane daemon configuration
# [*cp_config*]
#  Liberica control plane daemon configuration
# [*etcd_config*]
#  etcd configuration to be used by the control plane daemon
# [*bgp_config*]
#  bgp configuration to be used by the control plane daemon and gobgpd
# [*include_services*]
#  List of services (from the service catalog) to be configured in Liberica.
#  This config setting will be removed as soon as liberica becomes the main LB
# [*interface_tweaks*]
#  Hash using NIC name as key and a Hash of supported interface tweaks as value
#  see profile/manifests/lvs/interface_tweaks.pp for more details
class profile::liberica(
    Liberica::HcforwarderConfig $hcforwarder_config = lookup('profile::liberica::hcforwarder_config'),
    Liberica::HealthcheckConfig $healthcheck_config = lookup('profile::liberica::healthcheck_config'),
    Liberica::FpConfig $fp_config                   = lookup('profile::liberica::fp_config'),
    Liberica::CpConfig $cp_config                   = lookup('profile::liberica::cp_config'),
    Liberica::EtcdConfig $etcd_config               = lookup('profile::liberica::etcd_config'),
    Liberica::BgpConfig $bgp_config                 = lookup('profile::liberica::bgp_config'),
    Array[String] $include_services                 = lookup('profile::liberica::include_services'),
    Hash[String, Hash] $interface_tweaks            = lookup('profile::lvs::interface_tweaks'),
    String $gobgp_metrics_address                   = lookup('profile::liberica::gobgp_metrics_address'),
) {
    ensure_packages(['ethtool', 'ipip-multiqueue-optimizer', 'xdp-tools'])

    ## Kernel setup

    # defaults to "performance"
    class { 'cpufrequtils': }

    # kernel-level parameters
    class { 'lvs::kernel_config': }

    # temp hardcode the lvs class to fetch all the services as those will be filtered by $include_services
    $services = wmflib::service::get_services_for_lvs('parameter-not-used', $::site)
    $filtered_svcs = $services.filter|$svc_name, $svc| {
        $svc_name in $include_services
    }

    # Obtain all the IPs configured for this class of load-balancers,
    # as an array.
    $service_ips = wmflib::service::get_ips_for_services($filtered_svcs, $::site)

    # Bind VIPs to the loopback interface unless we are using katran
    if $fp_config['forwarding_plane'] != 'katran' {
        class { 'lvs::realserver':
            realserver_ips => sort($service_ips)
        }
    }

    # Apply needed interface tweaks

    create_resources(profile::lvs::interface_tweaks, $interface_tweaks, {ipip_enabled => true})


    # Configure ipip-multiqueue-optimizer
    $host_native_ifaces = $interface_tweaks.map|$iface_name, $tweaks| {
        $iface_name
    }

    $optimizer_interfaces = $host_native_ifaces
    $prometheus_addr = "${facts['networking']['ip']}:9095"
    systemd::service { 'ipip-multiqueue-optimizer':
        ensure               => present,
        content              => systemd_template('ipip-multiqueue-optimizer'),
        monitoring_enabled   => true,
        monitoring_notes_url => 'https://wikitech.wikimedia.org/wiki/LVS#IPIP_encapsulation_experiments',
        restart              => false,
    }

    # Provide egress interfaces for both IPv4 and IPv6 traffic
    # to be used by liberica hcforwarder
    interface::ipip { 'ipip_ipv4':
        ensure    => present,
        interface => 'ipip0',
        family    => 'inet',
        address   => '127.0.0.42',
    }
    interface::ipip { 'ipip_ipv6':
        ensure    => present,
        interface => 'ipip60',
        family    => 'inet6',
    }

    $config = {
        hcforwarder  => $hcforwarder_config,
        healthcheck  => $healthcheck_config,
        fp           => $fp_config,
        cp           => $cp_config,
        etcd         => $etcd_config,
        bgp          => $bgp_config,
        services     => liberica::service_from_wmflib($filtered_svcs, $::site),
    }

    class { 'liberica':
        config                => $config,
        gobgp_metrics_address => $gobgp_metrics_address,
    }

    # Report CPUs handling NIC queues
    $interface_tweaks.each|String $iface_name, Hash $tweaks| {
        prometheus::node_nic_queue_cpu { "nic-queue-cpu-${iface_name}":
            ensure    => present,
            interface => $iface_name,
            outfile   => "/var/lib/prometheus/node.d/nic-queue-cpu-${iface_name}.prom",
        }
    }
}
