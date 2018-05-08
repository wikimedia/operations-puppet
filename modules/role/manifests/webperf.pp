# == Class: role::webperf
#
# This role provisions a set of front-end monitoring tools that feed
# into StatsD.
#
class role::webperf {

    include ::standard
    include ::profile::base::firewall
    include ::profile::webperf

    # Based on graphite
    class { '::httpd':
        modules => ['uwsgi', 'proxy', 'proxy_http']
    }
    # Allow traffic to port 80 from internal networks
    ferm::service { 'performance-website-global':
        proto  => 'tcp',
        port   => '80',
        srange => '$DOMAIN_NETWORKS',
    }
    include ::profile::performance::coal
    include ::profile::performance::site
}
