# == class contint::worker_localhost
#
# Apache vhost for localhost testing (qunit/selenium)
#
# === Parameters
#
# [*owner*]
#   Unix user that runs the jobs. Should be:
#    - Permanent slaves: jenkins-deploy
#    - Nodepool slaves: jenkins
#
class contint::worker_localhost(
    $owner,
) {

    include ::apache::mod::rewrite

    file { '/srv/localhost-worker':
        ensure => directory,
        mode   => '0775',
        owner  => $owner,
        group  => 'root',
    }

    contint::localvhost { 'worker':
        port       => 9412,
        docroot    => '/srv/localhost-worker',
        log_prefix => 'worker',
        require    => File['/srv/localhost-worker'],
    }
}
