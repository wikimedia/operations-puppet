# == profile::ci::pipeline
#
# Profile that makes necessary provisions for building containers for
# production.
class profile::ci::pipeline() {
    include ::profile::ci::docker
    include ::docker_pusher
}
