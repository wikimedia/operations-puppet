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

    git::clone { 'performance/docroot':
        ensure    => latest,
        owner     => 'www-data',
        group     => 'www-data',
        directory => '/srv/org/wikimedia/performance',
        notify    => Service['apache2']
    }

    apache::site { 'performance.wikimedia.org':
        content => template('apache/sites/performance.wikimedia.org.erb'),
        require => Git::Clone['performance/docroot'],
    }
}
