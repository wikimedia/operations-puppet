# == Class profile::ci::worker_localhost
#
# Apache virtual host for localhost testing (qunit/selenium)
#
# === Parameters
#
# [*owner*]
# Unix user that runs the Jenkins job.
#
class profile::ci::worker_localhost(
    $owner=hiera('jenkins_agent_username'),
) {
    file { '/srv/localhost-worker':
        ensure => directory,
        mode   => '0775',
        owner  => 'jenkins-deploy',
        group  => 'root',
    }

    class { '::apache::mod::rewrite':
    }

    contint::localvhost { 'worker':
        port       => 9412,
        docroot    => '/srv/localhost-worker',
        log_prefix => 'worker',
        require    => [
            File['/srv/localhost-worker'],
            Class['::apache::mod::rewrite'],
        ],
    }

}
