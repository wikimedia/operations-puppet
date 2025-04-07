# SPDX-License-Identifier: Apache-2.0
class profile::thanos::compact (
    Stdlib::Fqdn $thanos_compact_host = lookup('profile::thanos::compact_host'),
    Hash[String, String] $objstore_account = lookup('profile::thanos::objstore_account'),
    String $objstore_password = lookup('profile::thanos::objstore_password'),
    String $retention_raw = lookup('profile::thanos::retention::raw', { 'default_value' => '270w' }),
    String $retention_5m = lookup('profile::thanos::retention::5m', { 'default_value' => '270w' }),
    String $retention_1h = lookup('profile::thanos::retention::1h', { 'default_value' => '270w' }),
    Integer $concurrency = lookup('profile::thanos::compactor::concurrency', { 'default_value' => 3 })
) {
    $http_port = 12902

    class { 'thanos::compact':
        run_on_host       => $thanos_compact_host,
        objstore_account  => $objstore_account,
        objstore_password => $objstore_password,
        http_port         => $http_port,
        retention_raw     => $retention_raw,
        retention_5m      => $retention_5m,
        retention_1h      => $retention_1h,
        concurrency       => $concurrency,
    }

    if $thanos_compact_host == $facts['networking']['fqdn'] {
        class { 'thanos::compact::prometheus': }
    }
}
