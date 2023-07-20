# SPDX-License-Identifier: Apache-2.0
class role::zookeeper::flink {
    system::role { 'zookeeper::flink':
        description => 'Flink Zookeeper cluster node'
    }
    include profile::base::production
    include profile::firewall

    include profile::zookeeper::server
    include profile::zookeeper::firewall
}
