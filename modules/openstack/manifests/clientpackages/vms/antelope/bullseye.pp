# SPDX-License-Identifier: Apache-2.0

# this is the class for use by VM instances in Cloud VPS. Don't use for HW servers
class openstack::clientpackages::vms::antelope::bullseye(
) {
    requires_realm('labs')

    apt::repository { 'openstack-antelope-bullseye':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'bullseye-antelope-backports',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.asc',
        notify     => Exec['openstack-antelope-bullseye-apt-upgrade'],
    }

    apt::repository { 'openstack-antelope-bullseye-nochange':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'bullseye-antelope-backports-nochange',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.asc',
        notify     => Exec['openstack-antelope-bullseye-apt-upgrade'],
    }

    # ensure apt can see the repo before any further Package[] declaration
    # so this proper repo/pinning configuration applies in the same puppet
    # agent run
    exec { 'openstack-antelope-bullseye-apt-upgrade':
        command     => '/usr/bin/apt-get update',
        require     => [Apt::Repository['openstack-antelope-bullseye'],
                        Apt::Repository['openstack-antelope-bullseye-nochange']],
        subscribe   => [Apt::Repository['openstack-antelope-bullseye'],
                        Apt::Repository['openstack-antelope-bullseye-nochange']],
        refreshonly => true,
        logoutput   => true,
    }
    Exec['openstack-antelope-bullseye-apt-upgrade'] -> Package <| title != 'gnupg' |>

}
