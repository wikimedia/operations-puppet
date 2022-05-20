# SPDX-License-Identifier: Apache-2.0

class role::ml_cache::storage {
    include profile::base::production
    include profile::base::firewall

    include profile::cassandra

    system::role { 'role::ml_cache::storage':
        description => 'Backend storage for ML cache and Online Feature Store.',
    }
}
