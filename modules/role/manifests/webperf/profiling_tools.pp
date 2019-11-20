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
    include ::profile::backup::host
    include ::profile::webperf::arclamp

    # class httpd installs mpm_event by default, and once installed,
    # it cannot easily be uninstalled.
    class { '::httpd::mpm':
        mpm => 'prefork'
    }

    # Web server (for arclamp)
    class { '::httpd':
        modules => ['authnz_ldap', 'php7.0', 'rewrite', 'mime', 'proxy', 'proxy_http'],
    }
}
