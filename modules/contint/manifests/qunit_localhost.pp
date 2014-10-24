class contint::qunit_localhost {

    include ::apache::mod::rewrite

    contint::localvhost { 'qunit':
        port       => 9412,
        docroot    => '/srv/localhost/qunit',
        log_prefix => 'qunit',
        require    => File['/srv/localhost/qunit'],
    }
}
