# == Class statistics::discovery::user
# Ensures that the discovery-stats user exists in the analytics-privatedata-users group.
# This means that you CANNOT include this class anywhere that the analytics-privatedata-users
# doesn't exist.
#
class statistics::discovery::user {
    # Homedir for everything Wikimedia Discovery Analytics related
    $dir = '/srv/discovery'

    $user = 'discovery-stats'
    # Setting group to 'analytics-privatedata-users' so that Discovery's Analysts
    # (as members of analytics-privatedata-users) have some privileges, and so
    # the discovery-stats user can access private data in Hive.
    $group ='analytics-privatedata-users'

    user { $user:
        ensure     => present,
        home       => $dir,
        shell      => '/bin/bash',
        managehome => false,
        system     => true,
        gid        => $group,
    }

    file { $dir:
        ensure => 'directory',
        owner  => $user,
        group  => $group,
        # so Discovery's Analysts (as members of analytics-privatedata-users group)
        # can read, write, execute
        mode   => '0775',
    }
}