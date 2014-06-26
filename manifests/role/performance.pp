# == Class: role::performance
#
# This role provisions <http://performance.wikimedia.org>, a static site with
# web performance dashboards.
#
class role::performance {
    include ::apache

    deployment::target { 'reporter': }

    file { '/var/www/performance':
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0444',
        purge   => true,
        recurse => true,
        force   => true,
        source  => 'puppet:///files/performance',
    }

    file { '/etc/apache2/sites-enabled/performance':
        content => template('apache/sites/performance.wikimedia.org.erb'),
        require => Package['apache2'],
    }
}
