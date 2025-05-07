# SPDX-License-Identifier: Apache-2.0

# this is the class for use by VM instances in Cloud VPS. Don't use for HW servers
class openstack::clientpackages::vms::epoxy::bookworm(
) {
    requires_realm('labs')

    apt::repository { 'openstack-epoxy-bookworm':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'bookworm-epoxy-backports',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.asc',
        notify     => Exec['openstack-epoxy-bookworm-apt-upgrade'],
    }

    apt::repository { 'openstack-epoxy-bookworm-nochange':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'bookworm-epoxy-backports-nochange',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.asc',
        notify     => Exec['openstack-epoxy-bookworm-apt-upgrade'],
    }

    # ensure apt can see the repo before any further Package[] declaration
    # so this proper repo/pinning configuration applies in the same puppet
    # agent run
    exec { 'openstack-epoxy-bookworm-apt-upgrade':
        command     => '/usr/bin/apt-get update',
        require     => [Apt::Repository['openstack-epoxy-bookworm'],
                        Apt::Repository['openstack-epoxy-bookworm-nochange']],
        subscribe   => [Apt::Repository['openstack-epoxy-bookworm'],
                        Apt::Repository['openstack-epoxy-bookworm-nochange']],
        refreshonly => true,
        logoutput   => true,
    }
    Exec['openstack-epoxy-bookworm-apt-upgrade'] -> Package <| title != 'gnupg' |>

}
