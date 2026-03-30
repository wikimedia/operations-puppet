# SPDX-License-Identifier: Apache-2.0
# == Class prometheus::ipip_exporter
# @summary Sets up centralized monitoring of realservers using IPIP/IP6IP6 to receive inbound traffic
# @param pushgateway_url Url of pushgateway instance
class prometheus::ipip_exporter(
    Wmflib::Ensure $ensure = 'present',
    Stdlib::HTTPUrl $pushgateway_url = 'http://prometheus-pushgateway.discovery.wmnet',
) {
    $site = $::site
    # Fetch LVS-only services that are active and have IPIP encapsulation and IPs defined
    $services = wmflib::service::fetch(true).filter |$pool, $svc| {
        $svc['state'] in ['lvs_setup', 'production'] and $svc['lvs']['ipip_encapsulation']
    }

    $pools = $services.reduce({}) |$memo, $svc_pair| {
        $svc_name = $svc_pair[0]
        $svc      = $svc_pair[1]


        if $site in $svc['lvs']['ipip_encapsulation'] and $svc['ip'][$site] != undef {
            # Get all VIPs for this site (may include v4 and v6)
            $vips = $svc['ip'][$site].values().flatten().unique()
            $fqdns = wmflib::service::get_pool_nodes($svc_name)


            $svc_pools = $vips.reduce({}) |$vip_memo, $vip| {
                $ip_version = $vip ? {
                    Stdlib::IP::Address::V4 => 4,
                    Stdlib::IP::Address::V6 => 6,
                }
                # Build the pool key: <service_name>-v<4|6>
                $pool_key = "${svc_name}-v${ip_version}"

                # Resolve node FQDNs to IPs matching the VIP version
                $node_ips = $fqdns.map |$fqdn| {
                    {
                        'hostname' => $fqdn,
                        'ip'       => ipresolve($fqdn, $ip_version),
                    }
                }

                $vip_memo + {
                    $pool_key => {
                        'vip'   => $vip,
                        'port'  => $svc['port'],
                        'nodes' => $node_ips,
                    }
                }
            }

            $memo + $svc_pools
        } else {
            $memo
        }
    }

    ensure_packages(['python3-scapy'])

    $config_path = '/etc/ipip-exporter.yaml'
    file { $config_path:
        ensure  => stdlib::ensure($ensure, 'file'),
        mode    => '0444',
        content => $pools.to_yaml(),
    }

    file { '/usr/local/bin/prometheus-ipip-exporter':
        ensure => stdlib::ensure($ensure, 'file'),
        mode   => '0555',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-ipip-exporter.py',
    }

    $ip = $::facts['networking']['ip']
    $ipv6 = $::facts['networking']['ip6']

    systemd::timer::job { 'prometheus-ipip-exporter':
        ensure             => $ensure,
        description        => 'Check IPIP capabilities on realservers',
        user               => 'root',
        command            => "/usr/local/bin/prometheus-ipip-exporter --config ${config_path} --inner-src-ipv4 ${ip} --inner-src-ipv6 ${ipv6} --pushgateway ${pushgateway_url}",
        fixed_random_delay => true,
        splay              => 300,
        interval           => [ { 'start' =>  'OnCalendar', 'interval' => '*:0/5' }, ],
    }
}
