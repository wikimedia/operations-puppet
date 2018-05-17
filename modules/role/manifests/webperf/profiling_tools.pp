# == Class: role::webperf::profiling_tools
#
# This role provisions a set of profiling tools for
# the performance team. (T194390)
#
class role::webperf::profiling_tools {

    system::role { 'webperf::profiling_tools':
        description => 'profiling tools for the performance team'
    }

    # lint:ignore:wmf_styleguide
    interface::add_ip6_mapped { 'main': }
    # lint:endignore

    include ::standard
    include ::profile::base::firewall

    include ::profile::webperf::xhgui

    class { '::httpd':
        modules => ['authnz_ldap', 'php7.0', 'rewrite'],
    }
}
