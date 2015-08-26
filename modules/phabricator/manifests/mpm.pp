# == Class: phabricator::mpm
#
# MPM tweaks for high load systems
# More performance specific tweaks to follow here

class phabricator::mpm {

    file { '/etc/apache2/mods-enabled/mpm_prefork.conf':
        content => template('phabricator/mpm_prefork.conf.erb'),
        notify  => Service['apache2'],
        require => Package['libapache2-mod-php5'],
    }
}
