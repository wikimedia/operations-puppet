# SPDX-License-Identifier: Apache-2.0

# this is the class for use by VM instances in Cloud VPS. Don't use for HW servers
class openstack::clientpackages::vms::yoga::bullseye(
) {
    requires_realm('labs')

    apt::repository { 'openstack-yoga-bullseye':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'bullseye-yoga-backports',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.gpg',
        notify     => Exec['openstack-yoga-bullseye-apt-upgrade'],
    }

    apt::repository { 'openstack-yoga-bullseye-nochange':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'bullseye-yoga-backports-nochange',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.gpg',
        notify     => Exec['openstack-yoga-bullseye-apt-upgrade'],
    }

    # ensure apt can see the repo before any further Package[] declaration
    # so this proper repo/pinning configuration applies in the same puppet
    # agent run
    exec { 'openstack-yoga-bullseye-apt-upgrade':
        command     => '/usr/bin/apt-get update',
        require     => [Apt::Repository['openstack-yoga-bullseye'],
                        Apt::Repository['openstack-yoga-bullseye-nochange']],
        subscribe   => [Apt::Repository['openstack-yoga-bullseye'],
                        Apt::Repository['openstack-yoga-bullseye-nochange']],
        refreshonly => true,
        logoutput   => true,
    }
    Exec['openstack-yoga-bullseye-apt-upgrade'] -> Package <| title != 'gnupg' |>

}
