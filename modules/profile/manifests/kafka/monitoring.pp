# SPDX-License-Identifier: Apache-2.0
# == class profile::kafka::cluster::monitoring
#
# Tools to monitor and expose metrics about a Kafka cluster
#
class profile::kafka::monitoring(
    Hash[String,Hash] $config             = lookup('profile::kafka::monitoring::config'),
    Array[String] $clusters               = lookup('profile::kafka::monitoring::clusters'),
) {

    profile::kafka::burrow { $clusters:
        monitoring_config => $config,
    }
}
