# SPDX-License-Identifier: Apache-2.0
class role::zookeeper::flink {
    include profile::base::production
    include profile::firewall

    include profile::zookeeper::server
    include profile::zookeeper::firewall
}
