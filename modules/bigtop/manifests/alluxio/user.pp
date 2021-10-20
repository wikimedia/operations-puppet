# == Class bigtop::alluxio::user
#
# Ensures that the alluxio user/group no longer exist.
#
class bigtop::alluxio::user {

    # Remove the alluxio group after first removing the user.
    group { 'alluxio':
        ensure  => 'absent',
        system  => true,
        gid     => 914,
        require => [
            User['alluxio']
        ],
    }

    # The alluxio user can now be removed since all of the packages have been removed.
    user { 'alluxio':
        ensure     => 'absent',
        uid        => 914,
        gid        => 'alluxio',
        shell      => '/bin/false',
        home       => '/var/lib/alluxio',
        system     => true,
        managehome => false,
    }
}
