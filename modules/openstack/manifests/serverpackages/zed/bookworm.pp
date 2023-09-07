# SPDX-License-Identifier: Apache-2.0

class openstack::serverpackages::zed::bookworm(
){
    $bookworm_bpo_packages = [
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

    apt::pin { 'openstack-zed-bookworm-bpo':
        package  => join($bookworm_bpo_packages, ' '),
        pin      => 'release n=bookworm-backports',
        priority => 1002,
    }

    # Force these packages to come from the nochange bpo
    #  even if they're available in the wikimedia repo.
    # This gets us the versions we require.
    $bookworm_bpo_nochange_packages = [
      'uwsgi-plugin-python3',
      'uwsgi-core',
      'librdkafka1',
      'python3-eventlet',
    ]

    apt::pin { 'openstack-zed-bookworm-bpo-nochange':
        package  => join($bookworm_bpo_nochange_packages, ' '),
        pin      => 'release n=bookworm-zed-backports-nochange',
        priority => 1002,
    }

    # Don't install systemd from bookworm-backports or bpo -- T247013
    apt::pin { 'systemd':
        pin      => 'release n=bookworm',
        package  => 'systemd libpam-systemd',
        priority => 1001,
    }

    apt::repository { 'openstack-zed-bookworm':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'bookworm-zed-backports',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.asc',
        notify     => Exec['openstack-zed-bookworm-apt-upgrade'],
    }

    apt::repository { 'openstack-zed-bookworm-nochange':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'bookworm-zed-backports-nochange',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.asc',
        notify     => Exec['openstack-zed-bookworm-apt-upgrade'],
    }

    # ensure apt can see the repo before any further Package[] declaration
    # so this proper repo/pinning configuration applies in the same puppet
    # agent run
    exec { 'openstack-zed-bookworm-apt-upgrade':
        command     => '/usr/bin/apt-get update',
        require     => [Apt::Repository['openstack-zed-bookworm'],
                        Apt::Repository['openstack-zed-bookworm-nochange']],
        subscribe   => [Apt::Repository['openstack-zed-bookworm'],
                        Apt::Repository['openstack-zed-bookworm-nochange']],
        refreshonly => true,
        logoutput   => true,
    }
    Exec['openstack-zed-bookworm-apt-upgrade'] -> Package <| title != 'gnupg' |>
}
