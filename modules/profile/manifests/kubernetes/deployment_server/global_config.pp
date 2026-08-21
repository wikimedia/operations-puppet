# SPDX-License-Identifier: Apache-2.0
# Kubernetes global configuration files.
# They include data that's useful to all deployed services.
#
class profile::kubernetes::deployment_server::global_config (
    Hash[String, Any] $general_values                         = lookup('profile::kubernetes::deployment_server::general', { 'default_value' => {} }),
    Stdlib::Unixpath $general_dir                             = lookup('profile::kubernetes::deployment_server::global_config::general_dir', { default_value => '/etc/helmfile-defaults' }),
    Array[Profile::Service_listener] $service_listeners       = lookup('profile::services_proxy::envoy::listeners', { 'default_value' => [] }),
    Hash[String, Hash] $kafka_clusters                        = lookup('kafka_clusters'),
    Hash[String, Integer] $db_sections                        = lookup('profile::mariadb::section_ports'),
    String $helm_user_group                                   = lookup('profile::kubernetes::deployment_server::helm_user_group'),
    Hash[String, Hash] $zookeeper_clusters                    = lookup('zookeeper_clusters'),
    String $kerberos_admin                                    = lookup('kerberos_kadmin_server_primary'),
    Array[String] $kerberos_servers                           = lookup('kerberos_kdc_servers_to_clients'),
    String $wikiadmin_username                                = lookup('profile::mariadb::wikiadmin_username'),
    Hash[String[3], Netbox::Device::Network] $network_devices = lookup('profile::netbox::data::network_devices'),
) {

    # General directory holding all configurations managed by puppet
    # that are used in helmfiles
    file { $general_dir:
        ensure => directory,
    }

    # directory holding private data for services
    # This is only writable by root, and readable by $helm_user_group.
    # Users not in this group can only traverse through it, but not read the contents.
    $general_private_dir = "${general_dir}/private"
    file { $general_private_dir:
        ensure => directory,
        owner  => 'root',
        group  => $helm_user_group,
        mode   => '0751',
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
            wmflib::ip2cidr($x)
        }
        $splits_data = $listener['splits']
        if ($splits_data == undef) {
            $splits = undef
        } else {
            $splits = $splits_data.map |$split_data| {
                $split_svc = $services_proxy[$split_data['service']]
                # To properly enable the networkpolicies, we also need to collect the service IPs
                $split_ip_addresses = $split_svc['ip'].map |$k, $v| { $v.values() }.flatten().unique().sort().map |$x| {
                    wmflib::ip2cidr($x)
                }
                $split = {
                    'name' => $split_data['name'],
                    'host_regex' => $split_data['host_regex'],
                    'ips' => $split_ip_addresses,
                    'address' => $split_data['upstream'],
                    'port' => $split_svc['port'],
                    'encryption' => $split_svc['encryption'],
                    'sets_sni' => $split_data['sets_sni'],
                    'sni_rewrites_host_header' => $split_data['sni_rewrites_host_header'],
                    'tcp_keepalive' => $split_data['tcp_keepalive'],
                    # TODO: Consider whether the RouteAction-level stream idle
                    # timeout should plausibly vary by upstream destination. If
                    # not, move it up to into the parent service_proxy item.
                    'idle_timeout'   => $listener['idle_timeout'],
                    'keepalive' => $split_data['keepalive'],
                }.filter |$key, $val| { $val =~ NotUndef }
            }
        }
        $upstream = {
                    'ips' => $ip_addresses,
                    'address' => $address,
                    'port' => $upstream_port,
                    'encryption' => $encryption,
                    'sets_sni'   => $listener['sets_sni'],
                    'sni_rewrites_host_header' => $listener['sni_rewrites_host_header'],
                    'tcp_keepalive'   => $listener['tcp_keepalive'],
                    # TODO: Consider whether the RouteAction-level stream idle
                    # timeout should plausibly vary by upstream destination. If
                    # not, move it up to into the parent service_proxy item.
                    'idle_timeout'   => $listener['idle_timeout'],
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
                'splits' => $splits,
            }.filter |$key, $val| { $val =~ NotUndef },
        }
    }.reduce({}) |$mem, $val| { $mem.merge($val) }

    $kafka_brokers = Hash($kafka_clusters.map |$cl, $data| {
        $ips = $data['brokers'].keys()
          .wmflib::hosts2ips()
          .map |$ip| { wmflib::ip2cidr($ip) }
        [$cl, $ips]
    })

    $zookeeper_nodes = Hash($zookeeper_clusters.map |$cl, $data| {
        $ips = $data['hosts'].keys()
          .wmflib::hosts2ips()
          .map |$ip| { wmflib::ip2cidr($ip) }
        [$cl, $ips]
    })

    $kerberos = {
      'admin'   => $kerberos_admin,
      'servers' => $kerberos_servers,
    }

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
    $mariadb_external_storage_eqiad_ips = profile::kubernetes::deployment_server::mariadb_external_storage_ips('eqiad')
    $mariadb_external_storage_codfw_ips = profile::kubernetes::deployment_server::mariadb_external_storage_ips('codfw')

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

    $gitlab_ips = dnsquery::lookup('gitlab.wikimedia.org', true).flatten.unique
    $rgw_eqiad_dpe_ips = dnsquery::lookup('rgw.eqiad.dpe.anycast.wmnet', true).flatten.unique
    $thanos_swift_eqiad_ips = dnsquery::lookup('thanos-swift.svc.eqiad.wmnet', true).flatten.unique
    $thanos_swift_codfw_ips = dnsquery::lookup('thanos-swift.svc.codfw.wmnet', true).flatten.unique
    $dumps_public_ips = dnsquery::lookup('dumps.wikimedia.org', true).flatten.unique
    $ldap_ro_eqiad_ips = dnsquery::lookup('ldap-ro.eqiad.wikimedia.org', true).flatten.unique
    $ldap_ro_codfw_ips = dnsquery::lookup('ldap-ro.codfw.wikimedia.org', true).flatten.unique
    $gerrit_lb_eqiad_public_ips = dnsquery::lookup('gerrit-lb.eqiad.wikimedia.org', true).flatten.unique
    $gerrit_lb_codfw_public_ips = dnsquery::lookup('gerrit-lb.codfw.wikimedia.org', true).flatten.unique
    $fr_tech_minio_eqiad = dnsquery::lookup('franio1001.frack.eqiad.wmnet', true).flatten.unique
    $fr_tech_minio_codfw = dnsquery::lookup('franio2001.frack.codfw.wmnet', true).flatten.unique
    $urldownloader_svc_ips = $services_proxy['urldownloader']['ip'].map |$k, $v| { $v.values() }.flatten().unique().sort()

    $external_service_opts = deep_merge(
      {
        'archiva' => {
          '_meta' => {
            'ports' => [
              {
                'name' => 'https',
                'port' => 443
              }
            ],
          },
          'instances' => {
            'legacy' => wmflib::role::ips('archiva'),
          }
        },
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
              {
                'name'     => 'yarn-resourcemanager-ipc',
                'port'     => 8032,
              },
              {
                'name'     => 'yarn-localizer',
                'port'     => 8040
              },
              {
                'name'     => 'yarn-resourcemanager-http',
                'port'     => 8088
              },
              {
                'name'     => 'dfs-http',
                'port'     => 50070
              }
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
                'name'     => 'journalnode',
                'port'     => 8485,
              },
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
            'maps-read-replicas-eqiad' => wmflib::role::ips('maps::replica', 'eqiad'),
            'maps-read-replicas-codfw' => wmflib::role::ips('maps::replica', 'codfw'),
            'maps-master-eqiad' => wmflib::role::ips('maps::master', 'eqiad'),
            'maps-master-codfw' => wmflib::role::ips('maps::master', 'codfw'),
            'maps-bookworm-read-replicas-codfw' => wmflib::role::ips('maps::replica_bookworm', 'codfw'),
            'maps-bookworm-master-codfw' => wmflib::role::ips('maps::master_bookworm', 'codfw'),
            'maps-bookworm-read-replicas-eqiad' => wmflib::role::ips('maps::replica_bookworm', 'eqiad'),
            'maps-bookworm-master-eqiad' => wmflib::role::ips('maps::master_bookworm', 'eqiad'),
            'maps-staging-master-codfw' => wmflib::role::ips('maps::staging', 'codfw'),
          },
        },
        'puppet' => {
          '_meta' => {
            'ports' => [
              {
                'name' => 'rsyncd',
                'port' => 873,
              },
            ],
          },
          'instances' => {
            'puppetdb-codfw' => wmflib::role::ips('puppetdb', 'codfw'),
            'puppetdb-eqiad' => wmflib::role::ips('puppetdb', 'eqiad'),
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
            'wikimedia' => $gitlab_ips,
          }
        },
        'wikimail' => {
          '_meta' => {
            'ports' => [
              {
                'name' => 'smtp',
                'port' => 25,
              },
              {
                'name' => 'smtps',
                'port' => 465,
              },
            ],
          },
          'instances' => {
            'mx' => wmflib::role::ips('postfix::mx_out'),
          }
        },
        's3' => {
          '_meta' => {
            'ports' => [
              {
                'name' => 'https',
                'port' => 443
              }
            ]
          },
          'instances' => {
            'eqiad-dpe' => $rgw_eqiad_dpe_ips
          }
        },
        'hive' => {
          '_meta' => {
            'ports' => [
              {
                'name' => 'metastore',
                'port' => 9083
              },
              {
                'name' => 'hiverserver2',
                'port' => 10000
              }
            ],
          },
          'instances' => {
            'analytics'      => wmflib::role::ips('analytics_cluster::coordinator'),
            'analytics_test' => wmflib::role::ips('analytics_test_cluster::coordinator'),
          }
        },
        'mariadb-external-storage' => {
          '_meta' => {
            'ports' => [
              {
                'name' => 'tcp',
                'port' => 3306
              },
            ],
          },
          'instances' => {
            'eqiad' => $mariadb_external_storage_eqiad_ips,
            'codfw' => $mariadb_external_storage_codfw_ips,
          }
        },
        'thanos-swift' => {
          '_meta' => {
            'ports' => [
              {
                'name' => 'https',
                'port' => 443
              },
            ],
          },
          'instances' => {
            'eqiad' => $thanos_swift_eqiad_ips,
            'codfw' => $thanos_swift_codfw_ips,
          }
        }
      },
      'dumps' => {
        '_meta' => {
          'ports' => [
            {
              'name' => 'https',
              'port' => 443
            },
          ],
        },
        'instances' => {
          # Now that dumps.wikimedia.org resolves to dumps-lb.eqiad.wikimedia.org, itself reolving
          # to the ipv4 of the active host and an ipv6 that does not match the host's, we need to merge
          # all these IPs together.
          'wikimedia' => (wmflib::role::ips('dumps::distribution::server') + $dumps_public_ips).unique,
        }
      },
      'urldownloader' => {
        '_meta' => {
          'ports' => [
            {
              'name' => 'http',
              'port' => 8080
            },
          ],
        },
        'instances' => {
          'wikimedia' => (wmflib::role::ips('url_downloader') + $urldownloader_svc_ips).unique,
        }
      },
      'prometheus-pushgateway' => {
        '_meta' => {
          'ports' => [
            {
              'name' => 'http',
              'port' => 80
            },
          ],
        },
        'instances' => {
          'eqiad' => wmflib::role::ips('prometheus', 'eqiad'),
          'codfw' => wmflib::role::ips('prometheus', 'codfw'),
        }
      },
      'ldap-ro' => {
        '_meta' => {
          'ports' => [
            {
              'name' => 'ldaps',
              'port' => 636
            },
          ],
        },
        'instances' => {
          'eqiad' => $ldap_ro_eqiad_ips,
          'codfw' => $ldap_ro_codfw_ips,
        }
      },
      'gerrit' => {
        '_meta' => {
          'ports' => [
            {
              'name' => 'https',
              'port' => 443
            },
          ],
        },
        'instances' => {
          'wikimedia' => ($gerrit_lb_eqiad_public_ips + $gerrit_lb_codfw_public_ips).unique,
        }
      },
      'minio' => {
        '_meta' => {
          'ports' => [
            {
              'name' => 's3',
              'port' => 9000
            },
          ],
        },
        'instances' => {
          'fr-tech-eqiad' => $fr_tech_minio_eqiad,
          'fr-tech-codfw' => $fr_tech_minio_codfw,
        }
      },
      'phabricator' => {
        '_meta' => {
          'ports' => [
            {
              'name' => 'https',
              'port' => 443
            },
          ],
        },
        'instances' => {
          'wikimedia' => wmflib::role::ips('phabricator'),
        }
      },
      'redis-lock' => {
        '_meta' => {
          'ports' => [
            {
              'name' => 'redis',
              'port' => 6378
            },
          ],
        },
        'instances' => {
          'wikimedia' => wmflib::role::ips('redis::lock::instance'),
        }
      },
      $external_service_redis,
    )

    # Per-cluster general defaults.
    # Fetch clusters excluding aliases, for aliases we create symlinks to the actual cluster defaults
    k8s::fetch_clusters(false).each | String $cluster_name, K8s::ClusterConfig $cluster_config | {
        $dc = $cluster_config['dc']
        $puppet_ca_data = file($facts['puppet_config']['localcacert'])

        # TODO: add info about the cluster group? So we don't need to have unique cluster names.
        # Merge default and environment specific general values with deployment config and service proxies
        $opts = deep_merge(
          $general_values['default'],
          $general_values[$cluster_name],
          {
            # FIXME: Do we still need puppet_ca_crt (images should use wmf-certificates debian package)
            'puppet_ca_crt'                 => $puppet_ca_data,
            'external_services_definitions' => $external_service_opts,
            'services_proxy'                => $proxies,
            # Temporary duplication of kafka/zookeeper details until all charts are migrated
            # to using the external-services chart to define their egress network policies
            # to external services
            'kafka_brokers'                 => $kafka_brokers,
            'zookeeper_clusters'            => $zookeeper_nodes,
            'mariadb'                       => { 'wikiadmin_user' => $wikiadmin_username, 'section_ports' => $db_sections },
            'kubernetesVersion'             => $cluster_config['version'],
            'kerberos'                      => $kerberos,
            'network_devices'               => $network_devices,
          }
        )
        $general_config_path = "${general_dir}/general-${cluster_name}.yaml"
        file { $general_config_path:
            content => to_yaml($opts),
            mode    => '0444',
        }

        # Repeat the basic cluster info for loading separately in more complex helmfile structures.
        $clusterinfo = {
          'kubernetesVersion' => $opts['kubernetesVersion'],
        }
        $clusterinfo_config_path = "${general_dir}/clusterinfo-${cluster_name}.yaml"
        file { $clusterinfo_config_path:
            content => to_yaml($clusterinfo),
            mode    => '0444',
        }

        # If this cluster has an alias, create symlinks for it
        if $cluster_config['cluster_alias'] {
            file { "${general_dir}/general-${$cluster_config['cluster_alias']}.yaml":
                ensure => 'link',
                target => $general_config_path,
            }
            file { "${general_dir}/clusterinfo-${$cluster_config['cluster_alias']}.yaml":
                ensure => 'link',
                target => $clusterinfo_config_path,
            }
        }

    }
}
