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
        if ($svc == undef) {
            fail("Service \"${listener['service']}\" not found in service::catalog")
        }
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
                'port' => $listener['port'],
                'http_host' => $listener['http_host'],
                'timeout'   => $listener['timeout'],
                'retry_policy' => $listener['retry'],
                'xfp' => $listener['xfp'],
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

    # Turn the puppet DB resources for Cassandra clusters into a hashmap of the form:
    # ['name_instance_dc']  => [ip1, ip2, ...]
    # e.g.:
    # ['ml_cache_a_eqiad']     => ['10.192.0.222', '10.192.16.190', '10.192.32.72']
    $cassandra_clusters = wmflib::puppetdb_query('resources[title, parameters] { type = "Cassandra::Instance" order by certname, title }').reduce({}) |$mem, $v| {
      $dc = $v['parameters']['dc']
      # Some clusters, like AQS, have spaces in their names. Replace them with
      # underscores for easier use here and in the deployment charts.
      $name = regsubst($v['parameters']['cluster_name'], ' ', '_', 'G')
      $instance = $v['title']
      $ip = $v['parameters']['listen_address']
      $k = "${name}_${instance}_${dc}".downcase()

      if $k in $mem {
        $mem + { $k => $mem[$k]+$ip }
      } else {
        $mem + { $k => [$ip]}
      }
    }

    $analytics_meta_master_ips = profile::kubernetes::deployment_server::mariadb_master_ips('Profile::Analytics::Database::Meta', 'an-mariadb')
    $analytics_test_meta_master_ips = profile::kubernetes::deployment_server::mariadb_master_ips('Profile::Analytics::Database::Meta', 'an-test-coord')

    $external_services_elasticsearch_cirrus = profile::kubernetes::deployment_server::elasticsearch_external_services_config('cirrus', ['eqiad', 'codfw'])
    $external_services_elasticsearch_cloudelastic = profile::kubernetes::deployment_server::elasticsearch_external_services_config('cloudelastic', ['eqiad'])
    $external_services_elasticsearch_relforge = profile::kubernetes::deployment_server::elasticsearch_external_services_config('relforge', ['eqiad'])
    $external_services_elasticsearch = $external_services_elasticsearch_cirrus + $external_services_elasticsearch_cloudelastic + $external_services_elasticsearch_relforge

    # Create one external services definition for each redis port (instance running on each node)
    # to allow services to explicitely specify which redis instance they want to connect to
    $redis_misc_ips = wmflib::role::ips('redis::misc::master') + wmflib::role::ips('redis::misc::slave')
    # The hiera key containing the redis instances is scoped to the redis::misc::master role
    # and therefore not accessible here. Lookup all redis::misc instances from puppetdb instead.
    $redis_misc_resources = wmflib::puppetdb_query('resources[title] { type = "Redis::Instance" and certname in resources[certname] { type = "Class" and title = "Role::Redis::Misc::Master" } group by title }')
    $redis_misc_instances = $redis_misc_resources.map |$r| { $r['title'] }
    $external_service_redis = $redis_misc_instances.map |$port| {
      {
        "redis-${port}" => {
          '_meta' => {
            'ports' => [
              {
                'name' => "redis-${port}",
                'port' => Stdlib::Port($port),
              },
            ],
          },
          'instances' => {
            'misc' => $redis_misc_ips,
          },
        },
      }
    }.reduce({}) |$mem, $val| { $mem.merge($val) }

    $gilab_ips = dnsquery::lookup('gitlab.wikimedia.org', true).flatten.unique

    $external_service_opts = deep_merge(
      {
        'kafka'  => {
          '_meta' => {
            'ports' => [
              {
                'name'     => 'plaintext',
                'port'     => 9092,
              },
              {
                'name'     => 'tls',
                'port'     => 9093,
              },
            ],
          },
          'instances' => $kafka_brokers,
        },
        'zookeeper' => {
          '_meta' => {
            'ports' => [
              {
                'name'     => 'client',
                'port'     => 2181,
              },
            ],
          },
          'instances' => $zookeeper_nodes,
        },
        'kerberos'  => {
          '_meta' => {
            'ports' => [
              {
                'name'     => 'ticket',
                'port'     => 88,
                'protocol' => 'UDP'
              },
              {
                'name'     => 'ticket-large',
                'port'     => 88,
              },
            ],
          },
          'instances' => {
            'kdc' => wmflib::role::ips('kerberos::kdc'),
          },
        },
        'hadoop-master' => {
          '_meta' => {
            'namespace' => 'hadoop',
            'ports'     => [
              {
                'name'     => 'namenode',
                'port'     => 8020,
              },
            ],
          },
          'instances' => {
            'analytics'      => wmflib::role::ips('analytics_cluster::hadoop::master') + wmflib::role::ips('analytics_cluster::hadoop::standby'),
            'analytics_test' => wmflib::role::ips('analytics_test_cluster::hadoop::master') + wmflib::role::ips('analytics_test_cluster::hadoop::standby'),
          },
        },
        'hadoop-worker' => {
          '_meta' => {
            'namespace' => 'hadoop',
            'ports'     => [
              {
                'name'     => 'datanode-data',
                'port'     => 50010,
              },
              {
                'name'     => 'datanode-metadata',
                'port'     => 50020,
              },
            ],
          },
          'instances' => {
            'analytics'      => wmflib::role::ips('analytics_cluster::hadoop::worker'),
            'analytics_test' => wmflib::role::ips('analytics_test_cluster::hadoop::worker'),
          },
        },
        'cas' => {
            '_meta' => {
              'ports' => [
                {
                  'name'     => 'https',
                  'port'     => 443,
                },
              ],
            },
            'instances' => {
              'idp'      => wmflib::role::ips('idp'),
              'idp_test' => wmflib::role::ips('idp_test'),
            },
        },
        'druid' => {
          '_meta' => {
            'ports' => [
              {
                'name'     => 'coordinator',
                'port'     => 8081,
              },
              {
                'name'     => 'broker',
                'port'     => 8082,
              },
              {
                'name'     => 'historical',
                'port'     => 8083,
              },
            ],
          },
          'instances' => {
            'analytics'      => wmflib::role::ips('druid::analytics::worker'),
            'analytics_test' => wmflib::role::ips('druid::test_analytics::worker'),
            'public'         => wmflib::role::ips('druid::public::worker'),
          },
        },
        'presto' => {
          '_meta' => {
            'ports' => [
              {
                'name'     => 'http',
                'port'     => 8280,
              },
              {
                'name'     => 'discovery',
                'port'     => 8281,
              },
            ],
          },
          'instances' => {
            'analytics'      => wmflib::role::ips('analytics_cluster::coordinator'),
            'analytics_test' => wmflib::role::ips('analytics_test_cluster::coordinator'),
          },
        },
        'cassandra'  => {
          '_meta' => {
            'ports' => [
              {
                'name'     => 'cassandra-client',
                'port'     => 9042,
                'protocol' => 'TCP'
              },
            ],
          },
          'instances' => $cassandra_clusters,
        },
        # Note that this section does _not_ contain the Wikimedia mariadb clusters.
        'mariadb' => {
          '_meta' => {
            'ports' => [
              {
                'name' => 'client',
                'port' => 3306,
              },
            ],
          },
          'instances' => {
            'analytics_meta_master' => $analytics_meta_master_ips,
            'analytics_meta' => wmflib::role::ips('analytics_cluster::mariadb'),
            'analytics_test_meta_master' => $analytics_test_meta_master_ips,
            'analytics_test_meta' => wmflib::role::ips('analytics_test_cluster::coordinator'),
          },
        },
        'postgresql' => {
          '_meta' => {
            'ports' => [
              {
                'name' => 'client',
                'port' => 5432,
              },
            ],
          },
          'instances' => {
            'analytics' => wmflib::role::ips('analytics_cluster::postgresql'),
          },
        },
        'opensearch' => {
          '_meta' => {
            'ports' => [
              {
                'name' => 'client',
                'port' => 9200,
              },
            ],
          },
          'instances' => {
            'datahubsearch' => wmflib::role::ips('analytics_cluster::datahub::opensearch'),
          },
        },
        'pki' => {
          '_meta' => {
            'ports' => [
              {
                'name' => 'https',
                'port' => 8443,
              },
            ],
          },
          'instances' => {
            'multirootca' => wmflib::role::ips('pki::multirootca'),
          },
        },
        'gitlab' => {
          '_meta' => {
            'ports' => [
              {
                'name' => 'https',
                'port' => 443,
              },
            ],
          },
          'instances' => {
            'wikimedia' => $gilab_ips,
          }
        }
      },
      $external_service_redis,
      $external_services_elasticsearch,
    )

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
            'external_services_definitions' => $external_service_opts,
            'services_proxy'                => $proxies,
            # Temporary duplication of kafka/zookeeper details until all charts are migrated
            # to using the external-services chart to define their egress network policies
            # to external services
            'kafka_brokers'                 => $kafka_brokers,
            'zookeeper_clusters'            => $zookeeper_nodes,

            'mariadb'                       => { 'section_ports' => $db_sections },
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
