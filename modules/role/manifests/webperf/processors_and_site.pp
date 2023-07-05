# == Class: role::webperf::processors_and_site
#
class role::webperf::processors_and_site {
    include ::profile::base::production
    include ::profile::firewall
    include ::profile::webperf::processors
    include ::profile::webperf::site
    include ::profile::tlsproxy::envoy # TLS termination

    system::role { 'webperf::processors_and_site':
        description => 'performance team data processor and performance.wikimedia.org server'
    }

    class { '::httpd':
        modules   => ['php7.4', 'rewrite', 'proxy', 'proxy_http', 'remoteip', 'headers', 'ssl'],
        http_only => true,
    }
}
