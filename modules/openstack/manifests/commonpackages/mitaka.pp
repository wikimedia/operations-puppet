class openstack::commonpackages::mitaka(
){
    # this class holds common package repo/pinning/installation configuration
    # for both client and server packages, only for the openstack mitaka release

    # We are using openstack mitaka from jessie in both jessie and stretch.
    # jessie-backports repo is about to be archived, we imported the relevant
    # packages into our reprepro

    # NOTE: 'openstack-mitaka-jessie' is not an arbitrary name, is the name of
    # the component in our reprepro apt repository
    apt::repository { 'openstack-mitaka-jessie':
        uri        => 'http://apt.wikimedia.org/wikimedia/',
        dist       => 'jessie-wikimedia',
        components => 'openstack-mitaka-jessie',
        trust_repo => true,
        source     => false,
    }
}
