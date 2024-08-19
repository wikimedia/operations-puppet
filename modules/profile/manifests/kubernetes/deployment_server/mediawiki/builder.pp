# SPDX-License-Identifier: Apache-2.0
class profile::kubernetes::deployment_server::mediawiki::builder(
    # TODO: migrate the hiera keys once the transition is completed.
    String $docker_user = lookup('profile::ci::pipeline::publisher::docker_registry_user'),
    String $docker_password = lookup('profile::ci::pipeline::publisher::docker_registry_password')

) {
    # Create the mwbuilder user. This is the user that is allowed to run docker-pusher to publish
    # the images, and that should run the tasks in repos/releng/release.
    require profile::mediawiki::system_users

    # provide the docker-pusher wrapper and relative credentials
    class { 'docker_pusher':
        docker_pusher_user       => 'mwbuilder',
        docker_registry_user     => $docker_user,
        docker_registry_password => $docker_password,
    }

    # Clone repos/releng/release
    git::clone { 'repos/releng/release':
        ensure    => present,
        directory => '/srv/mwbuilder/release',
        owner     => 'mwbuilder',
        source    => 'gitlab',
    }

    # Deployers should be able to execute whatever wrapper we will write for repos/releng/release
    # as user mwbuilder. And also the wrapper that updates the repos/releng/release repo
    sudo::group { 'deploy_build_image':
        group      => 'deployment',
        privileges => [
            'ALL = (mwbuilder) NOPASSWD: /srv/mwbuilder/release/make-container-image/build-images.py *',
            'ALL = (mwbuilder) NOPASSWD: /usr/local/bin/update-mediawiki-tools-release'
        ]
    }

    # Install a small wrapper around git pull --ff-only
    file { '/usr/local/bin/update-mediawiki-tools-release':
        ensure  => present,
        mode    => '0555',
        owner   => 'mwbuilder',
        group   => 'mwbuilder',
        content => "#!/bin/bash\ngit -C /srv/mwbuilder/release pull --ff-only\n",
    }
}
