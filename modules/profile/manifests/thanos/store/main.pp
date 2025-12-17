# SPDX-License-Identifier: Apache-2.0
# == Class: profile::thanos::store::main
#
# Thanos store implements the Store API on top of historical data in an object storage bucket.
#
# This specific instance (main) will serve all the blocks with data older than the cutoff threshold.
#
# = Parameters
# [*objstore_account*] The account to use to access object storage
# [*objstore_password*] The password to access object storage
# [*query_hosts*] A list of Thanos query hosts to allow access from.
# [*object_store_cutoff_days*] Blocks younger than this value (expressed in days as an integer) will be served directly from local Prometheus instances.
# [*min_time*] Start of time range limit to serve. Thanos Store will serve only metrics, which happened later than this value. Expressed as time duration relative to current time, such as -1d or 2h45m. Valid duration units are ms, s, m, h, d, w, y.

class profile::thanos::store::main (
    Hash[String, String] $objstore_account = lookup('profile::thanos::objstore_account'),
    String $objstore_password = lookup('profile::thanos::objstore_password'),
    Array $query_hosts = lookup('profile::thanos::frontends'),
    Optional[Integer] $object_store_cutoff_days = lookup('profile::thanos::object_store_cutoff_days', { 'default_value' => undef }),
    Optional[String] $min_time = lookup('profile::thanos::store::min_time', { 'default_value' => undef }),
    Array[Stdlib::Host] $memcached_hosts = lookup('profile::thanos::store::memcached_hosts'),
    Integer $limits_request_series = lookup('thanos_limits_request_series', { 'default_value' => 0 }), # lint:ignore:wmf_styleguide
) {
    $http_port = 11902
    $grpc_port = 11901

    thanos::store { 'main':
        objstore_account      => $objstore_account,
        objstore_password     => $objstore_password,
        http_port             => $http_port,
        grpc_port             => $grpc_port,
        # Thanos Store accepts input in the form of an interval (e.g., '15d' represents 15 days).
        # With respect to Thanos Rule, we also need to add a minus sign here
        # The cutoff parameter is expressed in days as an Integer, and here we adjust the format to the correct string.
        max_time              => sprintf('-%dd', $object_store_cutoff_days),
        min_time              => $min_time,
        consistency_delay     => '30m',
        tracing_enabled       => true,
        memcached_hosts       => $memcached_hosts,
        memcached_port        => 11211,
        limits_request_series => $limits_request_series,
    }
}
