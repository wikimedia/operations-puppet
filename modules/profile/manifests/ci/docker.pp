# == Class profile::ci::docker
#
# Configures a host to be a docker-backed Jenkins agent
#
# === Parameters
#
# [*repos*] list of repos that we need to cache on the docker hosts
#

class profile::ci::docker (
    $repos = hiera('profile::ci::docker::repos')
) {
    include ::docker
    include phabricator::arcanist
    include ::zuul

    class { 'contint::worker_localhost':
        owner => 'jenkins-deploy',
    }

    # Ensure jenkins-deploy membership in the docker group
    exec { 'jenkins-deploy docker membership':
        unless  => '/usr/bin/id -Gn jenkins-deploy | /bin/grep -q "\bdocker\b"',
        command => '/usr/sbin/usermod -aG docker jenkins-deploy',
    }

    create_resources(contint::git_cache, $repos)
}
