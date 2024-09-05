# SPDX-License-Identifier: Apache-2.0

class role::ml_cache::storage {
    include profile::base::production
    include profile::base::certificates
    include profile::firewall

    # lint:ignore:wmf_styleguide - It is neither a role nor a profile
    include passwords::cassandra
    # lint:endignore
    include profile::cassandra
}
