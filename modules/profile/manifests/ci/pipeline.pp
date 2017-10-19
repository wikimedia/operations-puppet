# == profile::ci::pipeline
#
# Profile that makes necessary provisions for building containers for
# production.
class profile::ci::pipeline(
    $docker_pusher_user = hiera('jenkins_agent_username'),
) {
    # We will need to build containers in production
    require_package('blubber')

    class{ '::docker_pusher':
        docker_pusher_user => $docker_pusher_user,
    }
}
