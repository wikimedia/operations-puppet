class torrus::web {

    package { 'torrus-apache2':
        ensure => latest,
        before => Class['webserver::apache::service'],
    }

    @webserver::apache::module { ['perl', 'rewrite']: }
    @webserver::apache::site { 'torrus.wikimedia.org':
        require  => Webserver::Apache::Module[['perl', 'rewrite']],
        docroot  => '/var/www',
        custom   => ['RedirectMatch ^/$ /torrus'],
        includes => ['/etc/torrus/torrus-apache2.conf']
    }
}
