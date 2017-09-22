# == Class profile::ci::docker
#
# Configures a host to be a docker-backed Jenkins agent
#

class profile::ci::docker(
    $jenkins_agent_username = hiera('jenkins_agent_username'),
) {
    include ::docker

    # Ensure membership in the docker group
    exec { "${jenkins_agent_username} docker membership":
        unless  => "/usr/bin/id -Gn '${jenkins_agent_username}'| /bin/grep -qw 'docker'",
        command => "/usr/sbin/usermod -aG docker '${jenkins_agent_username}'",
        require => [
            Class['::docker'],
        ],
    }
}
