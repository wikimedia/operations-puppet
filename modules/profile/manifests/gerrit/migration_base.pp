# set up user, group and data dir needed for rsyncing
# data on a new Gerrit host before it has the main role class
class profile::gerrit::migration_base (
    Stdlib::Unixpath $data_dir = lookup(profile::gerrit::migration::data_dir),
    String $user_name = lookup(profile::gerrit::migration::user_name),
){

    group { $user_name:
        ensure => present,
    }

    user { $user_name:
        ensure     => 'present',
        gid        => $user_name,
        shell      => '/bin/bash',
        home       => "/var/lib/${user_name}",
        system     => true,
        managehome => true,
    }

    file { $data_dir:
        ensure => directory,
        owner  => 'gerrit2',
        group  => 'gerrit2',
        mode   => '0664',
    }
}
