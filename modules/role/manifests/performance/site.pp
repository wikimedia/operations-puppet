# == Class: role::performance::site
#
# This role provisions <http://performance.wikimedia.org>, a static site with
# web performance dashboards.
#
class role::performance::site {
    include ::apache
    include ::apache::mod::headers
    include ::apache::mod::proxy
    include ::apache::mod::rewrite
    include ::apache::mod::uwsgi

    class { '::coal':
        endpoint => 'tcp://eventlogging.eqiad.wmnet:8600',
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

    apache::site { 'performance.wikimedia.org':
        content => template('role/apache/sites/performance.wikimedia.org.erb'),
        require => Git::Clone['performance/docroot'],
    }

    # Make Coal's whisper files accessible to Graphite front-ends.
    file { '/var/lib/carbon/whisper/coal':
        ensure => link,
        target => '/var/lib/coal',
    }
}
