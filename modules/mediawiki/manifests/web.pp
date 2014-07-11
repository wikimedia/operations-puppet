# mediawiki::web

class mediawiki::web ( $workers_limit = undef ) {
    include ::mediawiki
    include ::mediawiki::monitoring::webserver

    package{ 'apache2-mpm-prefork':
        ensure => present,
        before => Package['apache2']
    }

    include ::apache
    include ::mediawiki::web::config



    file { '/usr/local/apache':
        ensure => directory,
    }
}
