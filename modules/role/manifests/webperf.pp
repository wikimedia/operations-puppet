# == Class: role::webperf
#
# This role provisions a set of front-end monitoring tools that feed
# into StatsD.
#
class role::webperf {

    # lint:ignore:wmf_styleguide
    interface::add_ip6_mapped { 'main': }
    # lint:endignore

    include ::standard
    include ::profile::base::firewall
    include ::profile::webperf

    # Based on graphite
    class { '::httpd':
        modules => ['uwsgi', 'proxy', 'proxy_http']
    }
    include ::profile::performance::coal
    include ::profile::performance::site
}
