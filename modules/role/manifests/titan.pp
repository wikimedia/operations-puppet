# SPDX-License-Identifier: Apache-2.0

class role::titan {
    system::role { 'titan':
        description => 'Titan hosts Thanos components',
    }

    include ::profile::base::production
    include ::profile::firewall

    include ::profile::lvs::realserver

    include ::profile::tlsproxy::envoy

    include ::profile::thanos::query
    include ::profile::thanos::query_frontend
    include ::profile::thanos::httpd

    include ::profile::thanos::store
    include ::profile::thanos::compact

    include ::profile::thanos::bucket_web

    include ::profile::thanos::rule
    include ::profile::alerts::deploy::thanos
}
