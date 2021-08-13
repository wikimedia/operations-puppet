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

    # The alluxio user is a member of the hadoop group, which means that it has
    # superuser privileges on HDFS.
    user { 'alluxio':
        ensure     => 'present',
        uid        => 914,
        gid        => 'alluxio',
        shell      => '/bin/false',
        home       => '/var/lib/alluxio',
        system     => true,
        managehome => false,
        groups     => 'hadoop',
        require    => [
            Group['alluxio'], Group['hadoop']
        ],
    }
}
