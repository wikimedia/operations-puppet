# set up user, group and data dir needed for rsyncing
# data on a new Gerrit host before it has the main role class
class profile::gerrit::migration_base (
    Stdlib::Unixpath $data_dir = lookup('profile::gerrit::migration::data_dir'),
    String $user_name          = lookup('profile::gerrit::migration::user_name'),
    String $daemon_user        = lookup('profile::gerrit::daemon_user'),
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
        owner  => $daemon_user,
        group  => $daemon_user,
        mode   => '0664',
    }
}
