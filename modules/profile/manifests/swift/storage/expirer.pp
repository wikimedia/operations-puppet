# SPDX-License-Identifier: Apache-2.0
class profile::swift::storage::expirer (
    Wmflib::Ensure $ensure            = lookup('profile::swift::storage::expirer::ensure', { 'default_value' => 'absent' }),
    String         $swift_cluster     = lookup('profile::swift::cluster'),
    Tuple          $memcached_servers = lookup('profile::swift::proxy::memcached_servers')
) {
    class { '::swift::expirer':
        ensure               => $ensure,
        statsd_metric_prefix => "swift.${swift_cluster}.${::hostname}",
        memcached_servers    => $memcached_servers,
    }
}
