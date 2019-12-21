class openstack::serverpackages::pike::stretch(
){
    apt::repository { 'openstack-pike-stretch':
        uri        => 'http://osbpo.debian.net/debian',
        dist       => 'stretch-pike-backports',
        components => 'main',
        source     => false,
        notify     => Exec['openstack-pike-stretch-apt-upgrade'],
    }

    # ensure apt can see the repo before any further Package[] declaration
    # so this proper repo/pinning configuration applies in the same puppet
    # agent run
    exec { 'openstack-pike-stretch-apt-upgrade':
        command     => '/usr/bin/apt-get update',
        require     => Apt::Repository['openstack-pike-stretch'],
        subscribe   => Apt::Repository['openstack-pike-stretch'],
        refreshonly => true,
        logoutput   => true,
    }
    Exec['openstack-pike-stretch-apt-upgrade'] -> Package <| |>
}
