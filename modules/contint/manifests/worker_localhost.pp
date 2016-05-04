class contint::worker_localhost {

    include ::apache::mod::rewrite

    file { '/srv/localhost-worker':
        ensure => directory,
        mode   => '0775',
        owner  => 'jenkins-deploy',
        group  => 'root',
    }

    contint::localvhost { 'worker':
        port       => 9412,
        docroot    => '/srv/localhost-worker',
        log_prefix => 'worker',
        require    => File['/srv/localhost-worker'],
    }
}
