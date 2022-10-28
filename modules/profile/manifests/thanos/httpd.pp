# SPDX-License-Identifier: Apache-2.0
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
    class { 'httpd':
        modules => ['proxy_http'],
    }

    profile::idp::client::httpd::site {'thanos.wikimedia.org':
        vhost_content    => 'profile/idp/client/httpd-thanos.erb',
        proxied_as_https => true,
        document_root    => '/var/www/html',
        required_groups  => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
        ],
        vhost_settings   => {
            query_port      => $query_port,
            maxconn         => $maxconn,
            bucket_web_port => 15902,
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

    profile::auto_restarts::service { 'apache2': }
}
