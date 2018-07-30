# == Class: role::webperf::profiling_tools
#
# This role provisions a set of profiling tools for
# the performance team. (T194390)
#
class role::webperf::profiling_tools {

    include ::standard
    include ::profile::base::firewall

    system::role { 'webperf::profiling_tools':
        description => 'profiling tools host'
    }

    include ::profile::webperf::xhgui

    class { '::httpd':
        modules => ['authnz_ldap', 'php7.0', 'rewrite'],
    }
}
