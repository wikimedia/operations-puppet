# SPDX-License-Identifier: Apache-2.0

class openstack::serverpackages::xena::bullseye(
){
    $bullseye_bpo_packages = [
      'librados2',
      'librgw2',
      'librbd1',
      'ceph-common',
      'python3-ceph',
      'python3-cephfs',
      'python3-rados',
      'python3-rgw',
      'python3-rbd',
      'python3-tenacity',
      'libcephfs2',
      'libradosstriper1',
    ]

    apt::pin { 'openstack-xena-bullseye-bpo':
        package  => join($bullseye_bpo_packages, ' '),
        pin      => 'release n=bullseye-backports',
        priority => 1002,
    }

    # Force these packages to come from the nochange bpo
    #  even if they're available in the wikimedia repo.
    # This gets us the versions we require.
    $bullseye_bpo_nochange_packages = [
      'uwsgi-plugin-python3',
      'uwsgi-core',
      'librdkafka1',
      'python3-eventlet',
    ]

    apt::pin { 'openstack-xena-bullseye-bpo-nochange':
        package  => join($bullseye_bpo_nochange_packages, ' '),
        pin      => 'release n=bullseye-xena-backports-nochange',
        priority => 1002,
    }

    # Don't install systemd from bullseye-backports or bpo -- T247013
    apt::pin { 'systemd':
        pin      => 'release n=bullseye',
        package  => 'systemd libpam-systemd',
        priority => 1001,
    }

    apt::repository { 'openstack-xena-bullseye':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'bullseye-xena-backports',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.gpg',
        notify     => Exec['openstack-xena-bullseye-apt-upgrade'],
    }

    apt::repository { 'openstack-xena-bullseye-nochange':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'bullseye-xena-backports-nochange',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.gpg',
        notify     => Exec['openstack-xena-bullseye-apt-upgrade'],
    }

    # ensure apt can see the repo before any further Package[] declaration
    # so this proper repo/pinning configuration applies in the same puppet
    # agent run
    exec { 'openstack-xena-bullseye-apt-upgrade':
        command     => '/usr/bin/apt-get update',
        require     => [Apt::Repository['openstack-xena-bullseye'],
                        Apt::Repository['openstack-xena-bullseye-nochange']],
        subscribe   => [Apt::Repository['openstack-xena-bullseye'],
                        Apt::Repository['openstack-xena-bullseye-nochange']],
        refreshonly => true,
        logoutput   => true,
    }
    Exec['openstack-xena-bullseye-apt-upgrade'] -> Package <| title != 'gnupg' |>
}
