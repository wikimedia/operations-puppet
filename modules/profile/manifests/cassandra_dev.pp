# SPDX-License-Identifier: Apache-2.0

# Cassandra dev & test environment (T324113)
class profile::cassandra_dev {

    class {'passwords::cassandra': }
}
