# SPDX-License-Identifier: Apache-2.0
# == Class profile::lvs::realserver::ipip.
# Sets up the LVS realserver dependencies to handle IPIP encapsulated ingress traffic
#
# === Parameters
#
# [*pools*] Pools in the format: {$lvs_name => { services => [$svc1,$svc2,...] }
#           where the services listed are the ones that are needed to serve the lvs pool.
#           So for example if you need both apache and php7 to serve a request from a pool,
#           both should be included.
#
# [*enabled*] Whether to use IPIP encapsulation or not. Allows fine control per host. defaults to false.
#
# [*ipv4_mss*] TCP MSS value for IPv4 traffic. Defaults to 1400 bytes
#
# [*ipv6_mss*] TCP MSS value for IPv6 traffic. Defaults to 1400 bytes
#
# [*interfaces*] Network interfaces handling egress traffic on the realserver. Defaults to the primary interface
#
class profile::lvs::realserver::ipip(
    Hash $pools = lookup('profile::lvs::realserver::pools', {'default_value'                                                 => {}}),
    Boolean $enabled = lookup('profile::lvs::realserver::ipip::enabled', {'default_value'                                    => false}),
    Integer[536, 1480] $ipv4_mss = lookup('profile::lvs::realserver::ipip::ipv4_mss', {'default_value'                       => 1400}),
    Integer[1220, 1440] $ipv6_mss = lookup('profile::lvs::realserver::ipip::ipv6_mss', {'default_value'                      => 1400}),
    Array[String, 1] $interfaces = lookup('profile::lvs::realserver::ipip::interfaces'),
    Firewall::Provider $firewall_provider = lookup('profile::firewall::provider'),
) {
    $present_pools = $pools.keys()
    $services = wmflib::service::fetch(true).filter |$lvs_name, $svc| {$lvs_name in $present_pools}
    $clamped_ipport = wmflib::service::get_ipport_for_ipip_services($services, $::site)

    $ensure = stdlib::ensure($enabled)
    $ensure_clamper = stdlib::ensure($enabled and $firewall_provider == 'none')
    $ensure_ferm_mss = stdlib::ensure($enabled and $firewall_provider == 'ferm')
    if $enabled and $ensure_clamper == 'absent' and $ensure_ferm_mss == 'absent' {
        fail('unsupported realserver setup')
    }

    # Provide ingress interfaces for both IPv4 and IPv6 traffic
    interface::ipip { 'ipip_ipv4':
        ensure    => $ensure,
        interface => 'ipip0',
        family    => 'inet',
        address   => '127.0.0.42',
    }
    interface::ipip { 'ipip_ipv6':
        ensure    => $ensure,
        interface => 'ipip60',
        family    => 'inet6',
    }

    $interfaces.each |String $interface| {
        interface::clsact { "clsact_${interface}":
            ensure    => $ensure_clamper,
            interface => $interface,
        }
    }

    if $enabled {
        $disable_rp_filter_ifaces = ['ipip0', 'ipip60', $facts['interface_primary']]
        $disable_rp_filter_ifaces.each |String $interface| {
            $require_interface = $interface? {
                'ipip0'  => Interface::Ipip['ipip_ipv4'],
                'ipip60' => Interface::Ipip['ipip_ipv6'],
                default  => undef,
            }
            exec { "disable-rp-filter-${interface}":
                command => "/usr/sbin/sysctl -q net.ipv4.conf.${interface}.rp_filter=0",
                unless  => "/usr/sbin/sysctl -n net.ipv4.conf.${interface}.rp_filter |grep -- '0'",
                require => $require_interface,
            }
        }
    }

    # We need TCP MSS clamping here
    package { 'tcp-mss-clamper':
        ensure => $ensure_clamper,
    }

    $prometheus_addr = ':2200'
    systemd::service { 'tcp-mss-clamper':
        ensure               => $ensure_clamper,
        content              => systemd_template('tcp-mss-clamper'),
        monitoring_enabled   => true,
        monitoring_notes_url => 'https://wikitech.wikimedia.org/wiki/LVS#IPIP_encapsulation_experiments',
        restart              => false,
    }

    if $ensure_clamper == 'present' {
        exec { 'enable_tcp-mss-clamper_service':
            command => '/usr/bin/systemctl enable tcp-mss-clamper.service',
            unless  => '/usr/bin/systemctl -q is-enabled tcp-mss-clamper.service',
            require => Systemd::Service['tcp-mss-clamper'],
        }
    }

    if $firewall_provider == 'ferm' {
        $ensure_ferm_rules = $ensure
    } else {
        $ensure_ferm_rules = 'absent'
    }

    # Allow inbound IPIP && IP6IP6 traffic
    ferm::rule { 'ipip':
        ensure => $ensure_ferm_rules,
        rule   => 'saddr 172.16.0.0/12 proto ipencap ACCEPT;',
        domain => '(ip)',
    }
    ferm::rule { 'ip6ip6':
        ensure => $ensure_ferm_rules,
        rule   => 'saddr 0100::/64 proto ipv6 ACCEPT;',
        domain => '(ip6)',
    }
    # ferm based TCP MSS clamping
    $clamped_ips = $clamped_ipport.map|$ipport| {
        $ipport.match('\[?(.*)\]?:(.*)')[1]
    }.flatten().unique().sort()
    $clamped_ports = $clamped_ipport.map|$ipport| {
        $ipport.match('\[?(.*)\]?:(.*)')[2]
    }.flatten().unique().sort()

    $rule_ips = $clamped_ips? {
        Array[Stdlib::IP::Address, 1, 1] => $clamped_ips[0],
        Array                            => sprintf('(%s)', $clamped_ips.join(' ')),
    }
    $rule_ports = $clamped_ports? {
        Array[Stdlib::Port, 1, 1] => $clamped_ports[0],
        Array                     => sprintf('(%s)', $clamped_ports.join(' ')),
    }

    $outerfaces = $interfaces.join(' ')

    ferm::rule { 'clamp-mss-ipv4':
        ensure => $ensure_ferm_mss,
        chain  => 'OUTPUT',
        rule   => "outerface (${outerfaces}) saddr @ipfilter(${rule_ips}) proto tcp sport ${rule_ports} tcp-flags (SYN) SYN TCPMSS set-mss ${ipv4_mss};",
        domain => '(ip)',
    }
    ferm::rule { 'clamp-mss-ipv6':
        ensure => $ensure_ferm_mss,
        chain  => 'OUTPUT',
        rule   => "outerface (${$outerfaces}) saddr @ipfilter(${rule_ips}) proto tcp sport ${rule_ports} tcp-flags (SYN) SYN TCPMSS set-mss ${ipv6_mss};",
        domain => '(ip6)',
    }

    # monitor MSS values
    prometheus::node_lvs_realserver_mss { 'lvs_clamped_ipport':
        ensure         => $ensure,
        clamped_ipport => $clamped_ipport,
    }
}
