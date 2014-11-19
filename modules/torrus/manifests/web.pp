class torrus::web {
    package { 'torrus-apache2':
        ensure => present,
        before => Service['apache2'],
    }

    include ::apache::mod::rewrite
    include ::apache::mod::perl

    @webserver::apache::site { 'torrus.wikimedia.org':
        require  => Class['::apache::mod::rewrite', '::apache::mod::perl'],
        docroot  => '/var/www',
        custom   => ['RedirectMatch ^/$ /torrus'],
        includes => ['/etc/torrus/torrus-apache2.conf'],
    }
}
