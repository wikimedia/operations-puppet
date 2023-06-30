# set up user, group and data dir needed for rsyncing
# data on a new Gerrit host before it has the main role class
class profile::gerrit::migration_base (
    Stdlib::Unixpath $data_dir = lookup('profile::gerrit::migration::data_dir'),
    String $daemon_user        = lookup('profile::gerrit::migration::daemon_user'),
){

    group { $daemon_user:
        ensure => present,
    }

    user { $daemon_user:
        ensure     => present,
        gid        => $daemon_user,
        shell      => '/bin/bash',
        home       => "/var/lib/${daemon_user}",
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
