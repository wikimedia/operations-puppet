# == Class druid::cdh::hadoop::user
#
# Ensures that the druid user/group exist.
#
class druid::cdh::hadoop::user {

    group { 'druid':
        ensure => 'present',
        system => true,
    }
    user { 'druid':
        ensure     => 'present',
        gid        => 'druid',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
        require    => Group['druid'],
    }
}
