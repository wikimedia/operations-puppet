# == Class: role::performance::site
#
# This role provisions <http://performance.wikimedia.org>, a static site with
# web performance dashboards.
#
class role::performance::site {

    $coal_whisper_dir = hiera('performance::coal::coal_whisper_dir')

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
        notify    => Service['apache2']
    }

    httpd::site { 'performance.wikimedia.org':
        content => template('role/apache/sites/performance.wikimedia.org.erb'),
        require => Git::Clone['performance/docroot'],
    }

    # Make Coal's whisper files accessible to Graphite front-ends.
    file { '/var/lib/carbon/whisper/coal':
        ensure => link,
        target => $coal_whisper_dir,
    }
}
