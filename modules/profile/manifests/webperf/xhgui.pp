# == Class: profile::webperf::arclamp
#
# This class is still a work in progress!
# See https://phabricator.wikimedia.org/T180761.
#
# Provision XHGui, a graphical interface for XHProf data
# built on MongoDB. Used by the Performance Team.
#
# See also profile::webperf::site, which provisions a proxy
# to expose the service at <https://performance.wikimedia.org/xhgui/>.
#
class profile::webperf::xhgui {

    require_package('libapache2-mod-php7.0')

    ferm::service { 'webperf-xhgui-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$INTERNAL',
    }

    ferm::service { 'webperf-xhgui-mongo':
        proto  => 'tcp',
        port   => '27017',
        srange => '$INTERNAL',
    }

    class { '::mongodb': }
}
