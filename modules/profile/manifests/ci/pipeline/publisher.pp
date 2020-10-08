# == profile::ci::pipeline::publisher
#
# Pipeline server that can publish Docker images to the WMF registry.
#
class profile::ci::pipeline::publisher(
    String $docker_pusher_user = lookup('jenkins_agent_username'),
){
    require_package('python3-ruamel.yaml')

    class{ '::docker_pusher':
        docker_pusher_user => $docker_pusher_user,
    }
}
