# SPDX-License-Identifier: Apache-2.0

# Cassandra dev & test environment (T324113)
class profile::cassandra_dev {

    class {'passwords::cassandra': }

    # Temporary; Installed to facilitate ad-hoc testing of Kask
    # containers (see https://phabricator.wikimedia.org/T327954).
    ensure_packages(['docker.io', 'siege'])
}
