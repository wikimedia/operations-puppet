class webserver::apache2::rpaf {
    # NOTE: rpaf.conf defaults to just 127.0.01 - may need to
    # modify to include squid/varnish/nginx ranges depending
    # on use.
    package { 'libapache2-mod-rpaf':
        ensure => 'present',
    }
    apache_module { 'rpaf':
        name    => 'rpaf',
        require => Package['libapache2-mod-rpaf'],
    }
}

