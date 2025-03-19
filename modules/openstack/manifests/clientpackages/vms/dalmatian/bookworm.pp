# SPDX-License-Identifier: Apache-2.0

# this is the class for use by VM instances in Cloud VPS. Don't use for HW servers
class openstack::clientpackages::vms::dalmatian::bookworm(
) {
    requires_realm('labs')

    apt::repository { 'openstack-dalmatian-bookworm':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'bookworm-dalmatian-backports',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.asc',
        notify     => Exec['openstack-dalmatian-bookworm-apt-upgrade'],
    }

    apt::repository { 'openstack-dalmatian-bookworm-nochange':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'bookworm-dalmatian-backports-nochange',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.asc',
        notify     => Exec['openstack-dalmatian-bookworm-apt-upgrade'],
    }

    # ensure apt can see the repo before any further Package[] declaration
    # so this proper repo/pinning configuration applies in the same puppet
    # agent run
    exec { 'openstack-dalmatian-bookworm-apt-upgrade':
        command     => '/usr/bin/apt-get update',
        require     => [Apt::Repository['openstack-dalmatian-bookworm'],
                        Apt::Repository['openstack-dalmatian-bookworm-nochange']],
        subscribe   => [Apt::Repository['openstack-dalmatian-bookworm'],
                        Apt::Repository['openstack-dalmatian-bookworm-nochange']],
        refreshonly => true,
        logoutput   => true,
    }
    Exec['openstack-dalmatian-bookworm-apt-upgrade'] -> Package <| title != 'gnupg' |>

}
