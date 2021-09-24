# this is the class for use by VM instances in Cloud VPS. Don't use for HW servers
class openstack::clientpackages::vms::victoria::bullseye(
) {
    requires_realm('labs')

    apt::repository { 'openstack-victoria-bullseye':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'bullseye-victoria-backports',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.gpg',
        notify     => Exec['openstack-victoria-bullseye-apt-upgrade'],
    }

    apt::repository { 'openstack-victoria-bullseye-nochange':
        uri        => 'http://mirrors.wikimedia.org/osbpo',
        dist       => 'bullseye-victoria-backports-nochange',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/openstack/serverpackages/osbpo-pubkey.gpg',
        notify     => Exec['openstack-victoria-bullseye-apt-upgrade'],
    }

    # ensure apt can see the repo before any further Package[] declaration
    # so this proper repo/pinning configuration applies in the same puppet
    # agent run
    exec { 'openstack-victoria-bullseye-apt-upgrade':
        command     => '/usr/bin/apt-get update',
        require     => [Apt::Repository['openstack-victoria-bullseye'],
                        Apt::Repository['openstack-victoria-bullseye-nochange']],
        subscribe   => [Apt::Repository['openstack-victoria-bullseye'],
                        Apt::Repository['openstack-victoria-bullseye-nochange']],
        refreshonly => true,
        logoutput   => true,
    }
    Exec['openstack-victoria-bullseye-apt-upgrade'] -> Package <| title != 'gnupg' |>

}
