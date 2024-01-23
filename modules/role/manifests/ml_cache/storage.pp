# SPDX-License-Identifier: Apache-2.0

class role::ml_cache::storage {
    include profile::base::production
    include profile::base::certificates
    include profile::firewall

    include profile::cassandra
}
