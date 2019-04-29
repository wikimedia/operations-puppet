# == Class: role::webperf::processors_and_site
#
class role::webperf::processors_and_site {
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::webperf::processors
    include ::profile::webperf::coal_web
    include ::profile::webperf::site

    system::role { 'webperf::processors_and_site':
        description => 'performance team data processor and performance.wikimedia.org server'
    }

    class { '::httpd':
        modules => ['uwsgi', 'proxy', 'proxy_http', 'headers']
    }
}
