class contint::qunit_localhost {

    file { '/srv/localhost':
        ensure => directory,
        mode   => '0775',
        owner  => 'jenkins-slave',
        group  => 'jenkins-slave',
    }
    file { '/srv/localhost/qunit':
        ensure => directory,
        mode   => '0775',
        owner  => 'jenkins-slave',
        group  => 'jenkins-slave',
    }

    include ::apache::mod::rewrite

    contint::localvhost { 'qunit':
        port       => 9412,
        docroot    => '/srv/localhost/qunit',
        log_prefix => 'qunit',
        require    => File['/srv/localhost/qunit'],
    }

}
