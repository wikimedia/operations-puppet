# == Class: role::webperf::xhgui
#
# This provisions the front-end for the XHGui profiler (T180761).
#
# role::webperf::processors_and_site includes a reverse proxy server which
# exposes this web server as https://performance.wikimedia.org/xhgui.
#
# This is MySQL-based and replaced the previous role::xhgui::app
# which was the old MongoDB-backed version.
#
class role::webperf::xhgui {
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::webperf::xhgui

    system::role { 'webperf::xhgui':
        description => 'Web front-end for XHGui profiler'
    }

    class { '::httpd':
        modules => ['authnz_ldap', 'php7.3', 'rewrite'],
    }
}
