# == Class: role::performance
#
# This role provisions <http://performance.wikimedia.org>, a static site with
# web performance dashboards.
#
class role::performance {
    include ::apache
    include ::apache::mod::headers
    include ::apache::mod::proxy
    include ::apache::mod::rewrite
    include ::apache::mod::uwsgi

    class { '::coal':
        endpoint => 'tcp://eventlogging.eqiad.wmnet:8600',
    }

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

    apache::site { 'performance.wikimedia.org':
        content => template('apache/sites/performance.wikimedia.org.erb'),
        require => File['/var/www/performance'],
    }
}
