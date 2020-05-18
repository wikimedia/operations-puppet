# == Class: profile::thanos::httpd
#
# Setup httpd to proxy requests to thanos query running on localhost.
# While using such proxy is not strictly required, it provides consistency with
# other parts of the Prometheus deployment. For example: standard access/error
# logs, and nice urls (e.g. in Grafana datasources) without having to remember
# special ports.
#
# = Parameters
# [*query_port*] The port thanos-query runs on
#
# [*maxconn*]
#   The maximum number of connections per Apache worker.

class profile::thanos::httpd (
    Stdlib::Port::Unprivileged $query_port = lookup('profile::thanos::httpd::query_port', {'default_value' => 10902}),
    Integer $maxconn = lookup('profile::thanos::httpd::maxconn', {'default_value' => 10}),
) {
    class { '::httpd':
        modules => ['proxy_http'],
    }

    httpd::site { 'thanos-query':
        content => template('profile/thanos/httpd.conf.erb'),
    }
}
