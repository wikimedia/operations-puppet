# == Class: role::webperf::profiling_tools
#
# This role provisions a set of profiling tools for
# the performance team. (T194390)
#
class role::webperf::profiling_tools {

    system::role { 'webperf::profiling_tools':
        description => 'profiling tools host'
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log
    include ::profile::webperf::arclamp
    include ::profile::webperf::xhgui

    # class httpd installs mpm_event by default, and once installed,
    # it cannot easily be uninstalled. The xhgui profile installs
    # libapache2-mod-php7.0 which in turn installs mpm_prefork, which
    # fails if mpm_event is present. (T180761)
    class { '::httpd::mpm':
        mpm => 'prefork'
    }

    # Web server (for xhgui, and arclamp)
    class { '::httpd':
        modules => ['authnz_ldap', 'php7.0', 'rewrite', 'mime', 'proxy', 'proxy_http'],
    }
}
