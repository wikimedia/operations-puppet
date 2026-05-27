# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::memcached_exporter (
    String              $arguments        = lookup('profile::prometheus::memcached_exporter::arguments'),
) {
    class { 'prometheus::memcached_exporter':
        arguments => $arguments,
    }
}
