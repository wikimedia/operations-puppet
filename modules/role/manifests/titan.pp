# SPDX-License-Identifier: Apache-2.0

class role::titan {
    include profile::base::production
    include profile::firewall

    include profile::lvs::realserver
    include profile::lvs::realserver::ipip

    include profile::tlsproxy::envoy

    include profile::thanos::query
    include profile::thanos::query_frontend
    include profile::thanos::httpd

    include profile::thanos::store::main
    include profile::thanos::store::ruler
    include profile::thanos::compact

    include profile::thanos::bucket_web

    include profile::thanos::rule::main
    include profile::thanos::rule::pilot
    include profile::alerts::deploy::thanos
    include profile::slothslos::deploy::thanos

    include profile::pyrra::api
    include profile::pyrra::filesystem

    include profile::opentelemetry::collector

    include profile::memcached::instance
    include profile::memcached::memkeys

    include profile::prometheus::promtool
}
