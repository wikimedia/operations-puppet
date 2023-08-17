# SPDX-License-Identifier: Apache-2.0
# This profiles ships the base network set definitions for nftables (the equivalent to what is provided
# by modules/base/templates/firewall/defs.erb for Ferm. If you make changes, remember to update both,
# unless you are fully sure one of the definitions will exclusively be used with hosts using Ferm or nft
class profile::firewall::nftables_base_sets () {
    include network::constants

    nftables::set { 'INTERNAL':
        hosts => ['10.0.0.0/8',
                  '2620:0:860:100::/56',  # eqsin
                  '2620:0:861:100::/56',  # eqiad
                  '2620:0:863:100::/56',  # ulsfo
                  '2a02:ec80:300:100::/56',  # esams
                  '2a02:ec80:600:100::/56',  # drmrs
                  '2001:df2:e500:100::/56'],  # eqsin
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

    # $LABS_NETWORKS is meant to be a set of all labs networks
    nftables::set { 'LABS_NETWORKS':
        hosts => $network::constants::labs_networks,
    }

    # $CLOUD_NETWORKS is meant to be a set of all labs networks (alias for LABS_NETWORKS)
    nftables::set { 'CLOUD_NETWORKS':
        hosts => $network::constants::labs_networks,
    }

    # $CLOUD_NETWORKS_PUBLIC is meant to be a set of all Cloud public networks
    nftables::set { 'CLOUD_NETWORKS_PUBLIC':
        hosts => $network::constants::cloud_networks_public,
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

    nftables::set { 'NETWORK_INFRA':
        hosts => $network::constants::network_infra.values,
    }

    nftables::set { 'DEPLOYMENT_HOSTS':
        hosts => $network::constants::deployment_hosts,
    }

    nftables::set { 'CUMIN_MASTERS':
        hosts => $network::constants::cumin_masters,
    }

    nftables::set { 'CACHES':
        hosts => $network::constants::cache_hosts,
    }

    nftables::set { 'KAFKA_BROKERS_MAIN':
        hosts => $network::constants::kafka_brokers_main,
    }

    nftables::set { 'KAFKA_BROKERS_JUMBO':
        hosts => $network::constants::kafka_brokers_jumbo,
    }

    nftables::set { 'KAFKA_BROKERS_LOGGING':
        hosts => $network::constants::kafka_brokers_logging,
    }

    nftables::set { 'KAFKAMON_HOSTS':
        hosts => $network::constants::kafkamon_hosts,
    }

    nftables::set { 'ZOOKEEPER_HOSTS_MAIN':
        hosts => $network::constants::zookeeper_hosts_main,
    }

    nftables::set { 'ZOOKEEPER_FLINK_HOSTS':
        hosts => $network::constants::zookeeper_flink_hosts,
    }

    nftables::set { 'DRUID_PUBLIC_HOSTS':
        hosts => $network::constants::druid_public_hosts,
    }

    nftables::set { 'LABSTORE_HOSTS':
        hosts => $network::constants::labstore_hosts,
    }

    nftables::set { 'MYSQL_ROOT_CLIENTS':
        hosts => $network::constants::mysql_root_clients,
    }
}
