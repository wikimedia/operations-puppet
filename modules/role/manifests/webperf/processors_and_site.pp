# == Class: role::webperf
#
# This role provisions a set of front-end monitoring tools that feed
# into StatsD.
#
class role::webperf {

    include ::standard
    include ::profile::base::firewall

    include ::profile::webperf::base
    include ::profile::webperf::processors_and_site
    
    # Based on graphite
    class { '::httpd':
        modules => ['uwsgi', 'proxy', 'proxy_http']
    }
    include ::profile::performance::coal
    include ::profile::performance::site
}
