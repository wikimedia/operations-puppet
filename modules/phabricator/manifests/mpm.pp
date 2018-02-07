# == Class: phabricator::mpm
#
# MPM tweaks for high load systems
# More performance specific tweaks to follow here

class phabricator::mpm {
    httpd::conf { 'mpm_prefork':
        source => 'puppet:///modules/phabricator/apache/mpm_prefork.conf',
    }
}
