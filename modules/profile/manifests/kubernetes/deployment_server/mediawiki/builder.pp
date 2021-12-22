class profile::kubernetes::deployment_server::mediawiki::builder(
    # TODO: migrate the hiera keys once the transition is completed.
    String $docker_user = lookup('profile::ci::pipeline::publisher::docker_registry_user'),
    String $docker_password = lookup('profile::ci::pipeline::publisher::docker_registry_password')

) {
    # Create the mwbuilder user. Ensure it's part of the docker group
    user { 'mwbuilder':
        ensure     => present,
        gid        => 'docker',
        shell      => '/bin/false',
        comment    => '',
        home       => '/srv/mwbuilder',
        managehome => true,
        system     => true,
        require    => File['/srv/deployment']
    }


    # provide the docker-pusher wrapper and relative credentials
    class { 'docker_pusher':
        docker_pusher_user       => 'mwbuilder',
        docker_registry_user     => $docker_user,
        docker_registry_password => $docker_password,
    }

    # Clone mediawki/tools/release
    git::clone { 'mediawiki/tools/release':
        ensure    => present,
        directory => '/srv/mwbuilder/release',
        owner     => 'mwbuilder',

    }
    # Deployers should be able to execute whatever wrapper we will write for tools/release
    # as user mwbuilder.
    # TODO: add the new sudo rule to admin/data/data.yaml  for group 'deployment'
}
