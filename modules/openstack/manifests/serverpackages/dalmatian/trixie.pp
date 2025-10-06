# SPDX-License-Identifier: Apache-2.0

class openstack::serverpackages::dalmatian::trixie(
){
    $trixie_bpo_packages = [
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

    apt::pin { 'openstack-dalmatian-trixie-bpo':
        package  => join($trixie_bpo_packages, ' '),
        pin      => 'release n=trixie-backports',
        priority => 1002,
    }

    # Force these packages to come from the nochange bpo
    #  even if they're available in the wikimedia repo.
    # This gets us the versions we require.
    $trixie_bpo_nochange_packages = [
      'uwsgi-plugin-python3',
      'uwsgi-core',
      'librdkafka1',
      'python3-eventlet',
    ]

    apt::pin { 'openstack-dalmatian-trixie-bpo-nochange':
        package  => join($trixie_bpo_nochange_packages, ' '),
        pin      => 'release n=trixie-dalmatian-backports-nochange',
        priority => 1002,
    }

    # Don't install systemd from trixie-backports or bpo -- T247013
    apt::pin { 'systemd':
        pin      => 'release n=trixie',
        package  => 'systemd libpam-systemd',
        priority => 1001,
    }

    apt::repository { 'openstack-dalmatian-trixie':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'trixie-dalmatian-backports',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.asc',
        notify     => Exec['openstack-dalmatian-trixie-apt-upgrade'],
    }

    apt::repository { 'openstack-dalmatian-trixie-nochange':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'trixie-dalmatian-backports-nochange',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.asc',
        notify     => Exec['openstack-dalmatian-trixie-apt-upgrade'],
    }

    # ensure apt can see the repo before any further Package[] declaration
    # so this proper repo/pinning configuration applies in the same puppet
    # agent run
    exec { 'openstack-dalmatian-trixie-apt-upgrade':
        command     => '/usr/bin/apt-get update',
        require     => [Apt::Repository['openstack-dalmatian-trixie'],
                        Apt::Repository['openstack-dalmatian-trixie-nochange']],
        subscribe   => [Apt::Repository['openstack-dalmatian-trixie'],
                        Apt::Repository['openstack-dalmatian-trixie-nochange']],
        refreshonly => true,
        logoutput   => true,
    }
    Exec['openstack-dalmatian-trixie-apt-upgrade'] -> Package <| title != 'gnupg' |>
}
