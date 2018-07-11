# == Class: profile::performance::site
#
# This profile provisions <https://performance.wikimedia.org>,
# a static site with web performance dashboards.
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

    # Allow traffic to port 80 from internal networks
    ferm::service { 'performance-website-global':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }

    $server_name = 'performance.wikimedia.org'
    $xenondata_host = 'mwlog1001.eqiad.wmnet'
    $xhgui_host = 'tungsten.eqiad.wmnet'
    httpd::site { 'performance-wikimedia-org':
        content => template('profile/performance/site/performance-website.erb'),
        require => Git::Clone['performance/docroot'],
    }

    require_package('libapache2-mod-uwsgi')

}
