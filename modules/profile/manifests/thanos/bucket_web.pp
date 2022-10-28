# SPDX-License-Identifier: Apache-2.0
class profile::thanos::bucket_web (
    Hash[String, String] $objstore_account = lookup('profile::thanos::objstore_account'),
    String $objstore_password = lookup('profile::thanos::objstore_password'),
) {
    $http_port = 15902

    class { 'thanos::bucket_web':
        objstore_account  => $objstore_account,
        objstore_password => $objstore_password,
        http_port         => $http_port,
    }
}

