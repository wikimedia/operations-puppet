#  Install the 'apache2' package
class webserver::apache2 {

    include webserver::base

    package { 'apache2':
        ensure => 'present',
    }

    # ensure default site is removed
    apache_site { '000-default':
        ensure => 'absent',
        name   => '000-default',
    }
    apache_site { '000-default-ssl':
        ensure => 'absent',
        name   => '000-default-ssl',
    }
}
