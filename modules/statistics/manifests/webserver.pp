class statistics::webserver {
    include webserver::apache

    # make sure /var/log/apache2 is readable by wikidevs for debugging.
    # This won't make the actual log files readable, only the directory.
    # Individual log files can be created and made readable by
    # classes that manage individual sites.
    file { '/var/log/apache2':
        ensure  => directory,
        owner   => 'root',
        group   => 'wikidev',
        mode    => '0750',
        require => Class['webserver::apache'],
    }

    webserver::apache::module { ['rewrite', 'proxy', 'proxy_http']:
        require => Class['webserver::apache']
    }
}
