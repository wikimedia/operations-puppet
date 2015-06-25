class contint::mw_localhost {

    include ::apache::mod::rewrite

    contint::localvhost { 'mediawiki':
        port       => 9412,
        docroot    => '/srv/localhost/mediawiki',
        log_prefix => 'mediawiki',
        require    => File['/srv/localhost/mediawiki'],
    }
}
