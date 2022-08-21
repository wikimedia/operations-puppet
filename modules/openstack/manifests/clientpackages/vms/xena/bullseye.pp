# SPDX-License-Identifier: Apache-2.0

# this is the class for use by VM instances in Cloud VPS. Don't use for HW servers
class openstack::clientpackages::vms::xena::bullseye(
) {
    requires_realm('labs')

    apt::repository { 'openstack-wallaby-bullseye':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'bullseye-wallaby-backports',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.gpg',
        notify     => Exec['openstack-wallaby-bullseye-apt-upgrade'],
    }

    apt::repository { 'openstack-wallaby-bullseye-nochange':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'bullseye-wallaby-backports-nochange',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.gpg',
        notify     => Exec['openstack-wallaby-bullseye-apt-upgrade'],
    }

    # ensure apt can see the repo before any further Package[] declaration
    # so this proper repo/pinning configuration applies in the same puppet
    # agent run
    exec { 'openstack-wallaby-bullseye-apt-upgrade':
        command     => '/usr/bin/apt-get update',
        require     => [Apt::Repository['openstack-wallaby-bullseye'],
                        Apt::Repository['openstack-wallaby-bullseye-nochange']],
        subscribe   => [Apt::Repository['openstack-wallaby-bullseye'],
                        Apt::Repository['openstack-wallaby-bullseye-nochange']],
        refreshonly => true,
        logoutput   => true,
    }
    Exec['openstack-wallaby-bullseye-apt-upgrade'] -> Package <| title != 'gnupg' |>

}
