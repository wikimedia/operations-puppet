# SPDX-License-Identifier: Apache-2.0
# == profile::ci::pipeline::publisher
#
# Pipeline server that can publish Docker images to the WMF registry.
#
class profile::ci::pipeline::publisher(
    String $docker_pusher_user = lookup('jenkins_agent_username'),
    String $docker_registry_user = lookup('profile::ci::pipeline::publisher::docker_registry_user'),
    String $docker_registry_password = lookup('profile::ci::pipeline::publisher::docker_registry_password'),
){
    ensure_packages('python3-ruamel.yaml')

    class{ '::docker_pusher':
        docker_pusher_user       => $docker_pusher_user,
        docker_registry_user     => $docker_registry_user,
        docker_registry_password => $docker_registry_password,
    }
}
