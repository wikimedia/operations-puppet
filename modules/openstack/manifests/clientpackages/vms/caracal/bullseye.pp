# SPDX-License-Identifier: Apache-2.0

# this is the class for use by VM instances in Cloud VPS. Don't use for HW servers
class openstack::clientpackages::vms::caracal::bullseye(
) {
    requires_realm('labs')
    # The most recent Openstack version available for Bullseye is 'zed'

    apt::repository { 'openstack-zed-bullseye':
        uri                      => 'http://mirrors.wikimedia.org/osbpo',
        dist                     => 'bullseye-zed-backports',
        components               => 'main',
        source                   => false,
        allow_releaseinfo_change => true,
        keyfile                  => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.asc',
        notify                   => Exec['openstack-zed-bullseye-apt-upgrade'],
    }

    apt::repository { 'openstack-zed-bullseye-nochange':
        uri                      => 'http://mirrors.wikimedia.org/osbpo',
        dist                     => 'bullseye-zed-backports-nochange',
        components               => 'main',
        source                   => false,
        allow_releaseinfo_change => true,
        keyfile                  => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.asc',
        notify                   => Exec['openstack-zed-bullseye-apt-upgrade'],
    }

    # ensure apt can see the repo before any further Package[] declaration
    # so this proper repo/pinning configuration applies in the same puppet
    # agent run
    exec { 'openstack-zed-bullseye-apt-upgrade':
        command     => '/usr/bin/apt-get update --allow-releaseinfo-change',
        require     => [Apt::Repository['openstack-zed-bullseye'],
                        Apt::Repository['openstack-zed-bullseye-nochange']],
        subscribe   => [Apt::Repository['openstack-zed-bullseye'],
                        Apt::Repository['openstack-zed-bullseye-nochange']],
        refreshonly => true,
        logoutput   => true,
    }
    Exec['openstack-zed-bullseye-apt-upgrade'] -> Package <| title != 'gnupg' |>

    apt::repository { 'openstack-yoga-bullseye':
        ensure => absent
    }
    apt::repository { 'openstack-yoga-bullseye-nochange':
        ensure => absent
    }
    apt::repository { 'openstack-wallaby-bullseye':
        ensure => absent
    }
    apt::repository { 'openstack-wallaby-bullseye-nochange':
        ensure => absent
    }
    apt::repository { 'openstack-victoria-bullseye':
        ensure => absent
    }
    apt::repository { 'openstack-victoria-bullseye-nochange':
        ensure => absent
    }
}
