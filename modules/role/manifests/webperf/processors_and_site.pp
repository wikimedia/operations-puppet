# == Class: role::webperf::processors_and_site
#
# This role provisions a set of front-end monitoring tools that feed
# into StatsD.
#
class role::webperf::processors_and_site {

    include ::standard
    include ::profile::base::firewall

    system::role { 'webperf::processors_and_site':
        description => 'performance team data processors and performance.wikimedia.org site'
    }

    include ::profile::webperf::processors_and_site
    
    # Based on graphite
    class { '::httpd':
        modules => ['uwsgi', 'proxy', 'proxy_http']
    }
    include ::profile::performance::coal
    include ::profile::performance::site
}
