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
    Stdlib::Port::Unprivileged $query_port = lookup('profile::thanos::httpd::query_port'),
    Integer                    $maxconn    = lookup('profile::thanos::httpd::maxconn'),
) {
    class { '::httpd':
        modules => ['proxy_http'],
    }

    class {'profile::idp::client::httpd_legacy':
        vhost_settings => {
            query_port => $query_port,
            maxconn    => $maxconn,
        }
    }
    httpd::site { 'thanos-query':
        content => template('profile/thanos/httpd.conf.erb'),
    }

    ferm::service { 'thanos_httpd':
        proto  => 'tcp',
        port   => 80,
        srange => '$DOMAIN_NETWORKS',
    }
}
