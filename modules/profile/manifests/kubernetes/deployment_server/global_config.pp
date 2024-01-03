# SPDX-License-Identifier: Apache-2.0
# Kubernetes global configuration files.
# They include data that's useful to all deployed services.
#
class profile::kubernetes::deployment_server::global_config (
    Hash[String, Any] $general_values                   = lookup('profile::kubernetes::deployment_server::general', { 'default_value' => {} }),
    Stdlib::Unixpath $general_dir                       = lookup('profile::kubernetes::deployment_server::global_config::general_dir', { default_value => '/etc/helmfile-defaults' }),
    Array[Profile::Service_listener] $service_listeners = lookup('profile::services_proxy::envoy::listeners', { 'default_value' => [] }),
    Array[Stdlib::Fqdn] $prometheus_nodes               = lookup('prometheus_all_nodes'),
    Hash[String, Hash] $kafka_clusters                  = lookup('kafka_clusters'),
    Hash[String, Integer] $db_sections                  = lookup('profile::mariadb::section_ports'),
    String $helm_user_group                             = lookup('profile::kubernetes::deployment_server::helm_user_group'),
    Hash[String, Hash] $zookeeper_clusters              = lookup('zookeeper_clusters'),

) {
    # General directory holding all configurations managed by puppet
    # that are used in helmfiles
    file { $general_dir:
        ensure => directory,
    }

    # directory holding private data for services
    # This is only writable by root, and readable by $helm_user_group
    $general_private_dir = "${general_dir}/private"
    file { $general_private_dir:
        ensure => directory,
        owner  => 'root',
        group  => $helm_user_group,
        mode   => '0750',
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
        $split_data = $listener['split']
        if ($split_data == undef) {
            $split = undef
        } else {
            $split_svc = $services_proxy[$split_data['service']]
            # To properly enable the networkpolicies, we also need to collect the service IPs
            $split_ip_addresses = $split_svc['ip'].map |$k, $v| { $v.values() }.flatten().unique().sort().map |$x| {
                $retval = $x ? {
                    Stdlib::IP::Address::V4::Nosubnet => "${x}/32",
                    Stdlib::IP::Address::V6::Nosubnet => "${x}/128",
                    default                           => $x
                }
            }
            $split = {
                'percentage' => $split_data['percentage'],
                'address' => $split_data['upstream'],
                'port' => $split_svc['port'],
                'ips' => $split_ip_addresses,
                'encryption' => $split_svc['encryption'],
                'keepalive' => $split_data['keepalive'],
                'sets_sni' => $split_data['sets_sni'],
            }.filter |$key, $val| { $val =~ NotUndef }
        }
        $upstream = {
                    'ips' => $ip_addresses,
                    'address' => $address,
                    'port' => $upstream_port,
                    'encryption' => $encryption,
                    'sets_sni'   => $listener['sets_sni'],
                    'keepalive' => $listener['keepalive'],
        }.filter |$key, $val| { $val =~ NotUndef }
        $retval = {
            $listener['name'] => {
                # TODO: remove after all charts are at
                # mesh.configuration 1.5.0 or later
                'keepalive' => $listener['keepalive'],
                'port' => $listener['port'],
                'http_host' => $listener['http_host'],
                'timeout'   => $listener['timeout'],
                'retry_policy' => $listener['retry'],
                'xfp' => $listener['xfp'],
                # TODO: remove after all charts are at
                # mesh.configuration 1.5.0 or later
                'uses_ingress' => $listener['uses_ingress'],
                # TODO: remove after all charts are at
                # mesh.configuration 1.5.0 or later
                'sets_sni' => $listener['sets_sni'],
                'upstream' => $upstream,
                'split' => $split,
            }.filter |$key, $val| { $val =~ NotUndef },
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
        $retval = { $cl => $ips }
    }.reduce({}) |$mem, $val| { $mem.merge($val) }

    $zookeeper_nodes = $zookeeper_clusters.map |$cl, $data| {
        $ips = $data['hosts'].keys().map |$n| {
            $v4 = ipresolve($n)
            if (pick($data['ipv6'], true)) {
                $v6 = ipresolve($n, 6)
                $ret = ["${v4}/32", "${v6}/128"]
            } else {
                $ret = ["${v4}/32"]
            }
            $ret
        }.flatten()
        $retval = { $cl => $ips }
    }.reduce({}) |$mem, $val| { $mem.merge($val) }

    $kerberos_nodes = wmflib::role::ips('kerberos::kdc');
    $hadoop_analytics_master_node = wmflib::role::ips('analytics_cluster::hadoop::master');
    $hadoop_analytics_standby_node = wmflib::role::ips('analytics_cluster::hadoop::standby');
    $hadoop_analytics_worker_nodes = wmflib::role::ips('analytics_cluster::hadoop::worker');
    $hadoop_analytics_test_master_node = wmflib::role::ips('analytics_test_cluster::hadoop::master');
    $hadoop_analytics_test_standby_node = wmflib::role::ips('analytics_test_cluster::hadoop::standby');
    $hadoop_analytics_test_worker_nodes = wmflib::role::ips('analytics_test_cluster::hadoop::worker');

    # Per-cluster general defaults.
    # Fetch clusters excluding aliases, for aliases we create symlinks to the actual cluster defaults
    k8s::fetch_clusters(false).each | String $cluster_name, K8s::ClusterConfig $cluster_config | {
        $dc = $cluster_config['dc']
        $puppet_ca_data = file($facts['puppet_config']['localcacert'])

        $filtered_prometheus_nodes = $prometheus_nodes.filter |$node| { "${dc}.wmnet" in $node }.map |$node| { ipresolve($node) }

        # FIXME: What is prometheus_nodes used for?
        # FIXME: Do we still need puppet_ca_crt (images should use wmf-certificates debian package)
        unless empty($filtered_prometheus_nodes) {
            $deployment_config_opts = {
                'tls' => {
                    'telemetry' => {
                        'prometheus_nodes' => $filtered_prometheus_nodes,
                    },
                },
                'puppet_ca_crt' => $puppet_ca_data,
            }
        } else {
            $deployment_config_opts = {
                'puppet_ca_crt' => $puppet_ca_data,
            }
        }

        # TODO: add info about the cluster group? So we don't need to have unique cluster names.
        # Merge default and environment specific general values with deployment config and service proxies
        $opts = deep_merge(
          $general_values['default'],
          $general_values[$cluster_name],
          $deployment_config_opts,
          {
            'services_proxy'     => $proxies,
            'kafka_brokers'      => $kafka_brokers,
            'zookeeper_clusters' => $zookeeper_nodes,
            'mariadb'            => { 'section_ports' => $db_sections },
            'kerberos'           => { 'kdc' => $kerberos_nodes },
            'hadoop_masters'     => {
              'analytics' => $hadoop_analytics_master_node + $hadoop_analytics_standby_node,
              'analytics_test' => $hadoop_analytics_test_master_node + $hadoop_analytics_test_standby_node
            },
            'hadoop_workers'     => {
              'analytics' => $hadoop_analytics_worker_nodes,
              'analytics_test' => $hadoop_analytics_test_worker_nodes
            },
          }
        )
        $general_config_path = "${general_dir}/general-${cluster_name}.yaml"
        file { $general_config_path:
            content => to_yaml($opts),
            mode    => '0444',
        }

        # If this cluster has an alias, create a symlink for it
        if $cluster_config['cluster_alias'] {
            file { "${general_dir}/general-${$cluster_config['cluster_alias']}.yaml":
                ensure => 'link',
                target => $general_config_path,
            }
        }
    }
}
