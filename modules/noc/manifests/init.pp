# https://noc.wikimedia.org/
class noc {

    # NOC needs a working mediawiki installation at the moment
    # so it will need profile::mediawiki::common to be present.

    httpd::conf { 'define_HHVM':
        conf_type => 'env',
        content   => "export APACHE_ARGUMENTS=\"\$APACHE_ARGUMENTS -D HHVM\"",
    }

    include ::noc::php_engine

    if os_version('debian >= stretch') {
        require_package('libapache2-mod-php')
    } else {
        require_package('libapache2-mod-php5')
    }

    httpd::site { 'noc.wikimedia.org':
        content => template('noc/noc.wikimedia.org.erb'),
    }

    # Monitoring
    monitoring::service { 'http-noc':
        description   => 'HTTP-noc',
        check_command => 'check_http_url!noc.wikimedia.org!http://noc.wikimedia.org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Noc.wikimedia.org',
    }

}
