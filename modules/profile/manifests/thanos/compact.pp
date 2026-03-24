# SPDX-License-Identifier: Apache-2.0
class profile::thanos::compact (
    Hash[String, String] $objstore_account = lookup('profile::thanos::objstore_account'),
    String $objstore_password = lookup('profile::thanos::objstore_password'),
    String $retention_raw = lookup('profile::thanos::retention::raw', { 'default_value' => '270w' }),
    String $retention_5m = lookup('profile::thanos::retention::5m', { 'default_value' => '270w' }),
    String $retention_1h = lookup('profile::thanos::retention::1h', { 'default_value' => '270w' }),
    Integer $concurrency = lookup('profile::thanos::compactor::concurrency', { 'default_value' => 3 }),
    Integer $block_meta_fetch_concurrency = lookup('profile::thanos::compactor::block_meta_fetch_concurrency', { 'default_value' => 32 }),
) {
    $http_port = 12902

    class { 'thanos::compact':
        objstore_account             => $objstore_account,
        objstore_password            => $objstore_password,
        http_port                    => $http_port,
        retention_raw                => $retention_raw,
        retention_5m                 => $retention_5m,
        retention_1h                 => $retention_1h,
        concurrency                  => $concurrency,
        block_meta_fetch_concurrency => $block_meta_fetch_concurrency,
    }
}
