class smokeping::web {
    @webserver::apache::module { 'fcgid': }
    @webserver::apache::site { 'smokeping.wikimedia.org':
        require => Webserver::Apache::Module['fcgid'],
        docroot => '/var/www',
        includes => ['/etc/torrus/torrus-apache2.conf']
    }
}
