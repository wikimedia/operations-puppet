# SPDX-License-Identifier: Apache-2.0
class profile::thanos::store (
    Hash[String, String] $objstore_account = lookup('profile::thanos::objstore_account'),
    String $objstore_password = lookup('profile::thanos::objstore_password'),
    Array $query_hosts = lookup('profile::thanos::frontends'),
    Optional[String] $max_time = lookup('profile::thanos::store::max_time', { 'default_value' => undef }),
    Optional[String] $min_time = lookup('profile::thanos::store::min_time', { 'default_value' => undef }),
) {
    $http_port = 11902
    $grpc_port = 11901

    class { 'thanos::store':
        objstore_account  => $objstore_account,
        objstore_password => $objstore_password,
        http_port         => $http_port,
        grpc_port         => $grpc_port,
        max_time          => $max_time,
        min_time          => $min_time,
        consistency_delay => '30m',
    }

    # Allow access from query hosts
    $query_hosts_ferm = join($query_hosts, ' ')
    ferm::service { 'thanos_store_query':
        proto  => 'tcp',
        port   => $grpc_port,
        srange => "(@resolve((${query_hosts_ferm})) @resolve((${query_hosts_ferm}), AAAA))",
    }
}
