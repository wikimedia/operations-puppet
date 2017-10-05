# == profile::ci::pipeline
#
# Profile that makes necessary provisions for building containers for
# production.
class profile::ci::pipeline(
    $docker_pusher_user = hiera('jenkins_agent_username'),
) {
    include ::profile::ci::docker
    class{ '::docker_pusher':
        docker_pusher_user => $docker_pusher_user,
    }
}
