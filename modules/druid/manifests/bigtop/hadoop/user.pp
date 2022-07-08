# == Class druid::bigtop::hadoop::user
#
# Ensures that the druid user/group exist.
#
class druid::bigtop::hadoop::user {

    # We manage service system users in puppet classes, but declare
    # commented placeholders for them in the admin module's data.yaml file
    # to ensure that people don't accidentally add uid/gid conflicts.

    group { 'druid':
        ensure => 'present',
        system => true,
        gid    => 907,
    }
    user { 'druid':
        ensure     => 'present',
        uid        => 907,
        gid        => 'druid',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
        require    => Group['druid'],
    }
}
