# SPDX-License-Identifier: Apache-2.0
# @param docker_user the registry user used to publish the images
# @param docker_password the registry password used to publish the images
# @param deployment_server the fqdn of the active deployment server
class profile::kubernetes::deployment_server::mediawiki::builder(
    # TODO: migrate the hiera keys once the transition is completed.
    String $docker_user = lookup('profile::ci::pipeline::publisher::docker_registry_user'),
    String $docker_password = lookup('profile::ci::pipeline::publisher::docker_registry_password'),
    String $deployment_server = lookup('deployment_server'),

) {
    # Create the mwbuilder user. This is the user that is allowed to run docker-pusher to publish
    # the images, and that should run the tasks in repos/releng/release.
    require profile::mediawiki::system_users

    # provide the docker-pusher wrapper and relative credentials
    class { 'docker_pusher':
        docker_pusher_user       => 'mwbuilder',
        docker_registry_user     => $docker_user,
        docker_registry_password => $docker_password,
        allow_pull               => true,
    }

    # Clone repos/releng/release
    git::clone { 'repos/releng/release':
        ensure    => present,
        directory => '/srv/mwbuilder/release',
        owner     => 'mwbuilder',
        source    => 'gitlab',
    }

    # Deployers should be able to execute build-images.py, the wrapper that updates the
    # repos/releng/release checkout, and the scap subcommands that execute mwscript via docker.
    $scap_mwscript_allowed_args = [
        '--no-local-config',
        '--directory', '/srv/mediawiki-staging',
        '--user', 'www-data'
    ]
    $scap_mwscript_args = join($scap_mwscript_allowed_args, ' ')
    sudo::group { 'deploy_build_image':
        group      => 'deployment',
        privileges => [
            'ALL = (mwbuilder) NOPASSWD: /srv/mwbuilder/release/make-container-image/build-images.py *',
            'ALL = (mwbuilder) NOPASSWD: /usr/bin/scap clean-images',
            'ALL = (mwbuilder) NOPASSWD: /usr/local/bin/update-mediawiki-tools-release',
            "ALL = (mwbuilder) NOPASSWD: /usr/bin/scap mwscript ${scap_mwscript_args} -- *",
            "ALL = (mwbuilder) NOPASSWD: /usr/bin/scap mwscript ${scap_mwscript_args} --network -- *",
            "ALL = (mwbuilder) NOPASSWD: /usr/bin/scap mwshell ${scap_mwscript_args} -- *",
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

    # Periodically prune the MediaWiki images we publish above, so that the
    # restricted section of the registry doesn't grow without bound. This lives
    # here rather than in profile::kubernetes::deployment_server because the
    # script needs the /etc/docker-pusher/config.json credentials declared by
    # the docker_pusher class above.
    # docker-registryctl ships in python3-docker-report.
    stdlib::ensure_packages(['python3-docker-report'])

    file { '/usr/local/bin/delete-old-mediawiki-restricted-images':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/profile/kubernetes/deployment_server/delete-old-mediawiki-restricted-images.sh',
    }

    # Only the active deployment server should prune the registry, and only in
    # production: the restricted registry is not reachable from Cloud VPS.
    $prune_images_ensure = stdlib::ensure(
        $::realm == 'production' and $deployment_server == $facts['networking']['fqdn']
    )
    systemd::timer::job { 'delete-old-mediawiki-restricted-images':
        ensure             => $prune_images_ensure,
        description        => 'Delete old MediaWiki restricted images',
        user               => 'root',
        monitoring_enabled => true,
        command            => '/usr/local/bin/delete-old-mediawiki-restricted-images',
        interval           => {'start' => 'OnCalendar', 'interval' => 'Sat *-*-* 03:00:00'},
        splay              => 900,  # seconds
        timeout_start_sec  => 3600,
        require            => File['/usr/local/bin/delete-old-mediawiki-restricted-images'],
    }
}
