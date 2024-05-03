# SPDX-License-Identifier: Apache-2.0

# == Class role::cassandra_dev
#
# Configures the cassandra-dev cluster
class role::cassandra_dev {
    include profile::firewall
    include profile::base::production
    include profile::cassandra_dev
    include profile::cassandra
}
