# == Class: role::arclamp
#
# Host the Arc Lamp receiver (Redis), processors,
# and static file server.
#
# See also profile::arclamp::processor.
#
class role::arclamp {
    include profile::base::production
    include profile::firewall
    include profile::backup::host
    include profile::arclamp::processor
    include profile::arclamp::redis

    # class httpd installs mpm_event by default, and once installed,
    # it cannot easily be uninstalled.
    class { '::httpd::mpm':
        mpm => 'prefork'
    }

    # Web server (for arclamp)
    class { '::httpd':
        modules => ['headers', 'mime'],
    }
}
