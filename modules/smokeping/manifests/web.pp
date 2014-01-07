class smokeping::web {
    file { '/usr/share/smokeping/www/smokeping.fcgi':
        source => "puppet:///${module_name}/smokeping.fcgi",
        owner => root,
        group => root,
        mode => 0555,
    }

    @webserver::apache::module { 'fcgid': }
    @webserver::apache::site { 'smokeping.wikimedia.org':
        require => [Webserver::Apache::Module['fcgid'], File['/usr/share/smokeping/www/smokeping.fcgi']],
        docroot => '/var/www',
        custom => [
            'AliasMatch ^/($|smokeping\.cgi) /usr/share/smokeping/www/smokeping.fcgi',
            'Alias /images /var/cache/smokeping/images/'
            ],
    }
}
