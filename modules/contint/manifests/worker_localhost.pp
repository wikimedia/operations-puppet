class contint::worker_localhost {

    include ::apache::mod::rewrite

    contint::localvhost { 'worker':
        port       => 9412,
        docroot    => '/srv/localhost-worker',
        log_prefix => 'worker',
        require    => File['/srv/localhost-worker'],
    }
}
