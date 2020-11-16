class openstack::serverpackages::stein::buster(
){
    $buster_bpo_packages = [
      'librados2',
      'librgw2',
      'librbd1',
      'python-rados',
      'python-rbd',
      'ceph-common',
      'python3-ceph',
      'python3-cephfs',
      'python3-rados',
      'python3-rgw',
      'python3-rbd',
      'libcephfs2',
      'libradosstriper1',
    ]

    apt::pin { 'openstack-stein-buster-bpo':
        package  => join($buster_bpo_packages, ' '),
        pin      => 'release n=buster-backports',
        priority => '1002',
    }

    # Force these packages to come from the nochange bpo
    #  even if they're available in the wikimedia repo.
    # This gets us the versions we require.
    $buster_bpo_nochange_packages = [
      'uwsgi-plugin-python3',
      'uwsgi-core',
      'uwsgi-plugin-python',
    ]

    apt::pin { 'openstack-stein-buster-bpo-nochange':
        package  => join($buster_bpo_nochange_packages, ' '),
        pin      => 'release n=buster-stein-backports-nochange',
        priority => '1002',
    }

    # Don't install systemd from buster-backports or bpo -- T247013
    apt::pin { 'systemd':
        pin      => 'release n=buster',
        package  => 'systemd libpam-systemd',
        priority => '1001',
    }

    apt::repository { 'openstack-stein-buster':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'buster-stein-backports',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.gpg',
        notify     => Exec['openstack-stein-buster-apt-upgrade'],
    }

    apt::repository { 'openstack-stein-buster-nochange':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'buster-stein-backports-nochange',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.gpg',
        notify     => Exec['openstack-stein-buster-apt-upgrade'],
    }

    # ensure apt can see the repo before any further Package[] declaration
    # so this proper repo/pinning configuration applies in the same puppet
    # agent run
    exec { 'openstack-stein-buster-apt-upgrade':
        command     => '/usr/bin/apt-get update',
        require     => [Apt::Repository['openstack-stein-buster'],
                        Apt::Repository['openstack-stein-buster-nochange']],
        subscribe   => [Apt::Repository['openstack-stein-buster'],
                        Apt::Repository['openstack-stein-buster-nochange']],
        refreshonly => true,
        logoutput   => true,
    }
    Exec['openstack-stein-buster-apt-upgrade'] -> Package <| title != 'gnupg' |>
}
