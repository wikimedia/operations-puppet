# SPDX-License-Identifier: Apache-2.0
# Kubernetes global configuration files.
# They include data that's useful to all deployed services.
#
class profile::kubernetes::deployment_server::global_config(
    Hash[String, Hash] $cluster_groups = lookup('kubernetes_cluster_groups'),
    Hash[String, Any] $general_values = lookup('profile::kubernetes::deployment_server::general', {'default_value' => {}}),
    $general_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
    Array[Profile::Service_listener] $service_listeners = lookup('profile::services_proxy::envoy::listeners', {'default_value' => []}),
    Array[Stdlib::Fqdn] $prometheus_nodes = lookup('prometheus_all_nodes'),
    Hash[String, Hash] $kafka_clusters = lookup('kafka_clusters'),
    String $helm_user_group = lookup('profile::kubernetes::deployment_server::helm_user_group'),

) {
    # General directory holding all configurations managed by puppet
    # that are used in helmfiles
    file { $general_dir:
        ensure => directory
    }

    # directory holding private data for services
    # This is only writable by root, and readable by $helm_user_group
    $general_private_dir = "${general_dir}/private"
    file { $general_private_dir:
        ensure => directory,
        owner  => 'root',
        group  => $helm_user_group,
        mode   => '0750'
    }

    # Global data defining the services proxy upstreams
    # Services proxy list of definitions to use by our helm charts.
    # They come from two hiera data structures:
    # - profile::services_proxy::envoy::listeners
    # - service::catalog
    $services_proxy = wmflib::service::fetch()
    $proxies = $service_listeners.map |$listener| {
        $address = $listener['upstream'] ? {
            undef   => "${listener['service']}.discovery.wmnet",
            default => $listener['upstream'],
        }
        $svc = $services_proxy[$listener['service']]
        $upstream_port = $svc['port']
        $encryption = $svc['encryption']
        # To properly enable the networkpolicies, we also need to collect the service IPs
        $ip_addresses = $svc['ip'].map |$k, $v| { $v.values() }.flatten().unique().sort().map |$x| {
            $retval = $x ? {
                Stdlib::IP::Address::V4::Nosubnet => "${x}/32",
                Stdlib::IP::Address::V6::Nosubnet => "${x}/128",
                default                           => $x
            }
        }
        $retval = {
            $listener['name'] => {
                'keepalive' => $listener['keepalive'],
                'port' => $listener['port'],
                'http_host' => $listener['http_host'],
                'timeout'   => $listener['timeout'],
                'retry_policy' => $listener['retry'],
                'xfp' => $listener['xfp'],
                'uses_ingress' => $listener['uses_ingress'],
                'upstream' => {
                    'ips' => $ip_addresses,
                    'address' => $address,
                    'port' => $upstream_port,
                    'encryption' => $encryption,
                }
            }.filter |$key, $val| { $val =~ NotUndef }
        }
    }.reduce({}) |$mem, $val| { $mem.merge($val) }

    $kafka_brokers = $kafka_clusters.map |$cl, $data| {
        # We need both v4 and v6 addresses
        $ips = $data['brokers'].keys().map |$n| {
            $v4 = ipresolve($n)
            if (pick($data['ipv6'], true)) {
                $v6 = ipresolve($n, 6)
                $ret = ["${v4}/32", "${v6}/128"]
            } else {
                $ret = ["${v4}/32"]
            }
            $ret
        }.flatten()
        $retval = {$cl => $ips}
    }.reduce({}) | $mem, $val| { $mem.merge($val)}

    # Per-cluster general defaults.
    $cluster_groups.each |$_, $clusters| {
        $clusters.each |String $environment, $data| {
            $dc = $data['dc']
            $puppet_ca_data = file($facts['puppet_config']['localcacert'])

            $filtered_prometheus_nodes = $prometheus_nodes.filter |$node| { "${dc}.wmnet" in $node }.map |$node| { ipresolve($node) }

            unless empty($filtered_prometheus_nodes) {
                $deployment_config_opts = {
                    'tls' => {
                        'telemetry' => {
                            'prometheus_nodes' => $filtered_prometheus_nodes
                        }
                    },
                    'puppet_ca_crt' => $puppet_ca_data,
                }
            } else {
                $deployment_config_opts = {
                    'puppet_ca_crt' => $puppet_ca_data
                }
            }
            # TODO: add info about the cluster group? So we don't need to have unique cluster names.
            # Merge default and environment specific general values with deployment config and service proxies
            $opts = deep_merge($general_values['default'], $general_values[$environment], $deployment_config_opts, {'services_proxy' => $proxies, 'kafka_brokers' => $kafka_brokers})
            file { "${general_dir}/general-${environment}.yaml":
                content => to_yaml($opts),
                mode    => '0444'
            }
        }
    }
}
