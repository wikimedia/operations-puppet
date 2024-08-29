# SPDX-License-Identifier: Apache-2.0
# === Class profile::lvs
#
# Sets up a linux load-balancer.
#
class profile::lvs(
    Array[String] $tagged_subnets = lookup('profile::lvs::tagged_subnets'),
    Hash[String, Hash] $vlan_data = lookup('lvs::interfaces::vlan_data'),
    Hash[String, Hash] $interface_tweaks = lookup('profile::lvs::interface_tweaks'),
    Boolean $ipip_enabled = lookup('profile::lvs::ipip_enabled'),
    Boolean $do_ipv6_ra_primary = lookup('profile::lvs::do_ipv6_ra_primary', {'default_value' => false}),
){
    require profile::lvs::configuration

    $services = wmflib::service::get_services_for_lvs($profile::lvs::configuration::lvs_class, $::site)

    ## Kernel setup

    # defaults to "performance"
    class { '::cpufrequtils': }

    # kernel-level parameters
    class { 'lvs::kernel_config':
        do_ipv6_ra_primary => $do_ipv6_ra_primary,
    }

    ## LVS IPs setup
    # Obtain all the IPs configured for this class of load-balancers,
    # as an array.
    $service_ips = wmflib::service::get_ips_for_services($services, $::site)
    # Also, get the advertised instrumentation IPs:
    $i13n_ips = wmflib::service::get_i13n_ips_for_lvs()

    # Bind balancer IPs to the loopback interface
    class { '::lvs::realserver':
        realserver_ips => sort($service_ips + $i13n_ips)
    }

    # Monitoring sysctl
    $rp_args = inline_template('<%= @interfaces.split(",").map{|x| "net.ipv4.conf.#{x.gsub(/[_:.]/,"/")}.rp_filter=0" if !x.start_with?("lo") }.compact.join(",") %>')
    nrpe::monitor_service { 'check_rp_filter_disabled':
        description  => 'Check rp_filter disabled',
        nrpe_command => "/usr/local/lib/nagios/plugins/check_sysctl ${rp_args}",
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Monitoring/check_rp_filter_disabled',
    }

    profile::lvs::tagged_interface {$tagged_subnets:
        interfaces   => $vlan_data,
        ipip_enabled => $ipip_enabled,
    }

    # Apply needed interface tweaks

    create_resources(profile::lvs::interface_tweaks, $interface_tweaks, {ipip_enabled => $ipip_enabled, do_ipv6_ra_primary => $do_ipv6_ra_primary})


    # Install ipip-multiqueue-optimizer
    package { 'ipip-multiqueue-optimizer':
        ensure => stdlib::ensure($ipip_enabled),
    }

    $host_vlan_ifaces = $vlan_data.filter |$vlan_name, $vlan| {
        $::hostname in $vlan['iface']
    }.map |$vlan_name, $vlan| {
        # Interface name comes from profile::lvs::tagged_interface --> interface::tagged
        "vlan${vlan['id']}"
    }
    $host_native_ifaces = $interface_tweaks.map|$iface_name, $tweaks| {
        $iface_name
    }

    $optimizer_interfaces = $host_vlan_ifaces + $host_native_ifaces
    $prometheus_addr = "${::ipaddress}:9095"
    systemd::service { 'ipip-multiqueue-optimizer':
        ensure               => stdlib::ensure($ipip_enabled),
        content              => systemd_template('ipip-multiqueue-optimizer'),
        monitoring_enabled   => true,
        monitoring_notes_url => 'https://wikitech.wikimedia.org/wiki/LVS#IPIP_encapsulation_experiments',
        restart              => false,
    }

    if $ipip_enabled {
        exec { 'enable_ipip-multiqueue-optimizer_service':
            command => '/usr/bin/systemctl enable ipip-multiqueue-optimizer.service',
            unless  => '/usr/bin/systemctl -q is-enabled ipip-multiqueue-optimizer.service',
            require => Systemd::Service['ipip-multiqueue-optimizer'],
        }
    }
}
