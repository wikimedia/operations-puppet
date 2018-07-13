# https://noc.wikimedia.org/
class noc {

    # NOC needs a working mediawiki installation at the moment
    include ::mediawiki # lint:ignore:wmf_styleguide

    include ::apache # lint:ignore:wmf_styleguide

    apache::def { 'HHVM': }

    include ::mediawiki::web::php_engine

    include ::apache::mod::rewrite
    include ::apache::mod::headers

    if os_version('debian >= stretch') {
        require_package('libapache2-mod-php')
    } else {
        require_package('libapache2-mod-php5')
    }

    apache::site { 'noc.wikimedia.org':
        content => template('noc/noc.wikimedia.org.erb'),
    }

    # Monitoring
    monitoring::service { 'http-noc':
        description   => 'HTTP-noc',
        check_command => 'check_http_url!noc.wikimedia.org!http://noc.wikimedia.org'
    }

}
