# == Class profile::ci::docker
#
# Configures a host to be a docker-backed Jenkins agent
#
class profile::ci::docker {
    requires_realm('labs')

    class { '::profile::ci::docker_ce':
        jenkins_user => 'jenkins-deploy',
    }

    include phabricator::arcanist
    include ::zuul

    class { 'contint::worker_localhost':
        owner => 'jenkins-deploy',
    }
}
