# == Class: phabricator::mpm
#
# MPM tweaks for high load systems
# More performance specific tweaks to follow here

class phabricator::mpm {
    apache::conf { 'mpm_prefork':
        content => template('phabricator/mpm_prefork.conf.erb'),
    }
}
