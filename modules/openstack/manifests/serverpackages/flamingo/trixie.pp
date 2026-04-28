# SPDX-License-Identifier: Apache-2.0

class openstack::serverpackages::flamingo::trixie(
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

    apt::pin { 'openstack-trixie-flamingo-backports':
        package  => join($trixie_bpo_packages, ' '),
        pin      => 'release c=thirdparty/openstack-trixie-flamingo-backports',
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

    apt::pin { 'openstack-trixie-flamingo-backports-nochange':
        package  => join($trixie_bpo_nochange_packages, ' '),
        pin      => 'release c=thirdparty/openstack-trixie-flamingo-backports',
        priority => 1002,
    }

    apt::repository { 'openstack-trixie-flamingo-backports':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => 'trixie-wikimedia',
        components => 'thirdparty/openstack-trixie-flamingo-backports',
        source     => false,
        keyfile    => '/etc/apt/keyrings/wikimedia-archive-keyring.gpg',
        notify     => Exec['openstack-trixie-flamingo-apt-upgrade'],
    }

    # ensure apt can see the repo before any further Package[] declaration
    # so this proper repo/pinning configuration applies in the same puppet
    # agent run
    exec { 'openstack-trixie-flamingo-apt-upgrade':
        command     => '/usr/bin/apt-get update',
        require     => [Apt::Repository['openstack-trixie-flamingo-backports']],
        subscribe   => [Apt::Repository['openstack-trixie-flamingo-backports']],
        refreshonly => true,
        logoutput   => true,
    }
    Exec['openstack-trixie-flamingo-apt-upgrade'] -> Package <| title != 'gnupg' |>
}
