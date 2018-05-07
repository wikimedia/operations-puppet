# == Class: profile::performance::site
#
# This profile provisions <http://performance.wikimedia.org>, a static site with
# web performance dashboards.
#
class profile::performance::site {

    require ::profile::performance::coal

    file { '/srv/org':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/srv/org/wikimedia':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
    }

    git::clone { 'performance/docroot':
        ensure    => latest,
        owner     => 'www-data',
        group     => 'www-data',
        directory => '/srv/org/wikimedia/performance',
        notify    => Service['apache2'],
        require   => Package['apache2']
    }

    httpd::site { 'performance.wikimedia.org':
        content => template('profile/performance/site/performance.wikimedia.org.erb'),
        require => Git::Clone['performance/docroot'],
    }

    require_package('libapache2-mod-uwsgi')

}
