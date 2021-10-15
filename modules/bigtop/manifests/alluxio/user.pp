# == Class bigtop::alluxio::user
#
# Ensures that the alluxio user/group exist.
#
class bigtop::alluxio::user {

    group { 'alluxio':
        ensure => 'present',
        system => true,
        gid    => 914,
    }

    # The alluxio user is to be removed once all of the packages have been removed
    user { 'alluxio':
        ensure     => 'present',
        uid        => 914,
        gid        => 'alluxio',
        shell      => '/bin/false',
        home       => '/var/lib/alluxio',
        system     => true,
        managehome => false,
        require    => [
            Group['alluxio']
        ],
    }
}
