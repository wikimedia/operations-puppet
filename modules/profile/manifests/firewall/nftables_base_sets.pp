# SPDX-License-Identifier: Apache-2.0
# This profiles ships the base network set definitions for nftables (the equivalent to what is provided
# by modules/base/templates/firewall/defs.erb for Ferm. If you make changes, remember to update both,
# unless you are fully sure one of the definitions will exclusively be used with hosts using Ferm or nft
class profile::firewall::nftables_base_sets (
    Array[Stdlib::IP::Address] $cache_hosts           = lookup('cache_hosts'),
    Array[Stdlib::IP::Address] $cumin_masters         = lookup('cumin_masters'),
    Array[Stdlib::IP::Address] $deployment_hosts      = lookup('deployment_hosts'),
    Array[Stdlib::IP::Address] $druid_public_hosts    = lookup('druid_public_hosts'),
    Array[Stdlib::IP::Address] $kafka_brokers_jumbo   = lookup('kafka_brokers_jumbo'),
    Array[Stdlib::IP::Address] $kafka_brokers_logging = lookup('kafka_brokers_logging'),
    Array[Stdlib::IP::Address] $kafka_brokers_main    = lookup('kafka_brokers_main'),
    Array[Stdlib::IP::Address] $kafkamon_hosts        = lookup('kafkamon_hosts'),
    Array[Stdlib::IP::Address] $labstore_hosts        = lookup('labstore_hosts'),
    Array[Stdlib::IP::Address] $monitoring_hosts      = lookup('monitoring_hosts'),
    Array[Stdlib::IP::Address] $mysql_root_clients    = lookup('mysql_root_clients'),
    Array[Stdlib::Host]        $prometheus_nodes      = lookup('prometheus_nodes'),
    Array[Stdlib::IP::Address] $zookeeper_flink_hosts = lookup('zookeeper_flink_hosts'),
    Array[Stdlib::IP::Address] $zookeeper_hosts_main  = lookup('zookeeper_hosts_main'),
) {

    include network::constants

    nftables::set { 'INTERNAL':
        hosts => ['10.0.0.0/8',
                  '2620:0:860:100::/56',  # eqsin
                  '2620:0:861:100::/56',  # eqiad
                  '2620:0:863:100::/56',  # ulsfo
                  '2a02:ec80:300:100::/56',  # esams
                  '2a02:ec80:600:100::/56',  # drmrs
                  '2a02:ec80:700:100::/56',  # magru
                  '2001:df2:e500:100::/56',  # eqsin
                  '2a02:ec80:ff00:100::/56'], # global
    }

    # $DOMAIN_NETWORKS is a set of all networks belonging to a domain.
    # a domain is a realm currently, but the notion is more generic than that on purpose
    nftables::set { 'DOMAIN_NETWORKS':
        hosts => $network::constants::domain_networks,
    }

    # $PRODUCTION_NETWORKS is a set of all production networks
    nftables::set { 'PRODUCTION_NETWORKS':
        hosts => $network::constants::production_networks,
    }

    # $LABS_NETWORKS is a deprecated alias for $CLOUD_NETWORKS
    nftables::set { 'LABS_NETWORKS':
        hosts => $network::constants::cloud_networks,
    }

    # $CLOUD_NETWORKS is a set of all Cloud VPS instance networks
    nftables::set { 'CLOUD_NETWORKS':
        hosts => $network::constants::cloud_networks,
    }

    # $CLOUD_NETWORKS_PUBLIC is meant to be a set of all Cloud public networks
    nftables::set { 'CLOUD_NETWORKS_PUBLIC':
        hosts => $network::constants::cloud_networks_public,
    }

    # $CLOUD_PRIVATE_NETWORKS is the cloud-private networks with WMCS
    # hardware with cloud realm private 172.20.x.x addresses. These
    # hosts are dual-homed, usually also in at least cloud-hosts.
    nftables::set { 'CLOUD_PRIVATE_NETWORKS':
        hosts => $network::constants::all_cloud_private_networks,
    }

    # $FRACK_NETWORKS is meant to be a set of all fundraising networks
    nftables::set { 'FRACK_NETWORKS':
        hosts => $network::constants::frack_networks,
    }

    nftables::set { 'ANALYTICS_NETWORKS':
        hosts => $network::constants::analytics_networks,
    }

    nftables::set { 'MW_APPSERVER_NETWORKS':
        hosts => $network::constants::mw_appserver_networks,
    }

    nftables::set { 'WIKIKUBE_KUBEPODS_NETWORKS':
        hosts => $network::constants::services_kubepods_networks,
    }

    nftables::set { 'STAGING_KUBEPODS_NETWORKS':
        hosts => $network::constants::staging_kubepods_networks,
    }

    nftables::set { 'MLSERVE_KUBEPODS_NETWORKS':
        hosts => $network::constants::mlserve_kubepods_networks,
    }

    nftables::set { 'MLSTAGE_KUBEPODS_NETWORKS':
        hosts => $network::constants::mlstage_kubepods_networks,
    }

    nftables::set { 'DSE_KUBEPODS_NETWORKS':
        hosts => $network::constants::dse_kubepods_networks,
    }

    nftables::set { 'MGMT_NETWORKS':
        hosts => $network::constants::mgmt_networks,
    }

    # nftables::set { 'NETWORK_INFRA':
    #     hosts => $network::constants::network_infra.values,
    # }

    nftables::set { 'DEPLOYMENT_HOSTS':
        hosts => $deployment_hosts,
    }

    nftables::set { 'CUMIN_MASTERS':
        hosts => $cumin_masters,
    }

    nftables::set { 'CACHES':
        hosts => $cache_hosts,
    }

    nftables::set { 'KAFKA_BROKERS_MAIN':
        hosts => $kafka_brokers_main,
    }

    nftables::set { 'KAFKA_BROKERS_JUMBO':
        hosts => $kafka_brokers_jumbo,
    }

    nftables::set { 'KAFKA_BROKERS_LOGGING':
        hosts => $kafka_brokers_logging,
    }

    nftables::set { 'KAFKAMON_HOSTS':
        hosts => $kafkamon_hosts,
    }

    nftables::set { 'ZOOKEEPER_HOSTS_MAIN':
        hosts => $zookeeper_hosts_main,
    }

    nftables::set { 'ZOOKEEPER_FLINK_HOSTS':
        hosts => $zookeeper_flink_hosts,
    }

    nftables::set { 'DRUID_PUBLIC_HOSTS':
        hosts => $druid_public_hosts,
    }

    nftables::set { 'LABSTORE_HOSTS':
        hosts => $labstore_hosts,
    }

    nftables::set { 'MYSQL_ROOT_CLIENTS':
        hosts => $mysql_root_clients,
    }

    unless $monitoring_hosts.empty() {
        nftables::set { 'MONITORING_HOSTS':
            hosts => $monitoring_hosts,
        }
    }

    unless $prometheus_nodes.empty() {
        nftables::set { 'PROMETHEUS_HOSTS':
            hosts => $prometheus_nodes,
        }
    }
}
