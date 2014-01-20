# manifests/role/torrus.pp

class role::torrus {

    system::role { 'torrus': description => 'Torrus' }

    include ::torrus

    @webserver::apache::site { 'torrus.wikimedia.org':
        require  => Webserver::Apache::Module[['perl', 'rewrite']],
        docroot  => '/var/www',
        custom   => ['RedirectMatch ^/$ /torrus'],
        includes => ['/etc/torrus/torrus-apache2.conf']
    }
}
