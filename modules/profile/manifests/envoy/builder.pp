# SPDX-License-Identifier: Apache-2.0
# Add tools to build envoy
class profile::envoy::builder {
    # we need a very large /tmp because the envoy build dumps more than 100 GB of
    # waste into it.
    labs_lvm::volume { 'tmp':
        size      => '50%FREE',
        mountat   => '/tmp',
        mountmode => '777',
    }
    # We need some space to use pbuilder with.
    labs_lvm::volume { 'pbuilder':
        size    => '20%FREE',
        mountat => '/var/cache/pbuilder'
    }
    # Where the source code for envoy is going to be, and also the produced artifacts.
    labs_lvm::volume { 'sources':
        size    => '10G',
        mountat => '/usr/src',
    }
    # We also need a volume to use for docker.
    labs_lvm::volume { 'docker':
        size    => '10%FREE',
        mountat => '/var/lib/docker',
        before  => Class['docker'],
    }

    # Now let's ensure envoy sources are checked out
    git::clone { 'operations/debs/envoyproxy':
        directory => '/usr/src/envoyproxy',
        require   => Labs_lvm::Volume['sources']
    }

    systemd::timer::job { 'git_pull_envoy':
        ensure                    => present,
        description               => 'Pull changes on the envoyproxy repo',
        command                   => '/bin/bash -c "cd /usr/src/envoyproxy && /usr/bin/git pull --rebase --tags>/dev/null 2>&1"',
        interval                  => {
            'start'    => 'OnUnitInactiveSec',
            'interval' => '60s',
        },
        logging_enabled           => false,
        monitoring_contact_groups => 'admins',
        user                      => 'root',
    }


    # Install an ugly script that automates building envoy.
    file { '/usr/local/bin/build-envoy-deb':
        source => 'puppet:///modules/profile/envoy/build_envoy_deb.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
    }
}
