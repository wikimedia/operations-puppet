class openstack::serverpackages::ocata::stretch(
){
    # NOTE: 'openstack-ocata-stretch' is not an arbitrary name, is the name of
    # the component in our reprepro apt repository
    apt::repository { 'openstack-ocata-stretch':
        uri        => 'http://apt.wikimedia.org/wikimedia/',
        dist       => 'stretch-wikimedia',
        components => 'openstack-ocata-stretch',
        source     => false,
        notify     => Exec['openstack-ocata-stretch-apt-upgrade'],
    }

    # ensure apt can see the repo before any further Package[] declaration
    # so this proper repo/pinning configuration applies in the same puppet
    # agent run
    exec { 'openstack-ocata-stretch-apt-upgrade':
        command     => '/usr/bin/apt-get update',
        require     => Apt::Repository['openstack-ocata-stretch'],
        subscribe   => Apt::Repository['openstack-ocata-stretch'],
        refreshonly => true,
        logoutput   => true,
    }
    Exec['openstack-ocata-stretch-apt-upgrade'] -> Package <| |>
}
