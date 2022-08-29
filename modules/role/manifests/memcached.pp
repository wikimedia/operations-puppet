# SPDX-License-Identifier: Apache-2.0
class role::memcached{

    system::role { 'memcached':
        description => 'Basic memcached role.',
    }

    include ::profile::base::production
    include ::profile::base::firewall
    include profile::memcached::instance
    include profile::memcached::memkeys
    include profile::memcached::performance
}
