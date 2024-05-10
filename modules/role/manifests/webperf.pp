# == Class: role::webperf
#
# Details at profile::webperf::processors and profile::webperf::site.
#
class role::webperf {
    include profile::base::production
    include profile::firewall
    include profile::webperf::processors
    include profile::webperf::site
    include profile::tlsproxy::envoy # TLS termination

    class { '::httpd':
        modules   => ['php7.4', 'rewrite', 'proxy', 'proxy_http', 'remoteip', 'headers', 'ssl'],
        http_only => true,
    }
}
