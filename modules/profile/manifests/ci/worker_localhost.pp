# == Class profile::ci::worker_localhost
#
class profile::ci::worker_localhost(
    $jenkins_agent_username = hiera('jenkins_agent_username'),
) {
    class { '::contint::worker_localhost':
        owner => $jenkins_agent_username,
    }
}
