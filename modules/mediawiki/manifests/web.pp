# mediawiki::web

class mediawiki::web ( $workers_limit = undef ) {
    include ::mediawiki
    include ::mediawiki::monitoring::webserver

    include ::mediawiki::web::config

    file { '/usr/local/apache':
        ensure => directory,
    }
}
