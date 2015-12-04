class torrus::web {
    package { 'torrus-apache2':
        ensure => present,
        before => Service['apache2'],
    }

    include ::apache::mod::rewrite
    include ::apache::mod::headers
    include ::apache::mod::perl

    apache::site { 'torrus.wikimedia.org':
        source => 'puppet:///modules/torrus/apache.conf',
    }
}
