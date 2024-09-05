# SPDX-License-Identifier: Apache-2.0

# == Class role::cassandra_dev
#
# Configures the cassandra-dev cluster
class role::cassandra_dev {
    include profile::firewall
    include profile::base::production
    include profile::cassandra_dev
    # lint:ignore:wmf_styleguide - It is neither a role nor a profile
    include passwords::cassandra
    # lint:endignore
    include profile::cassandra
}
