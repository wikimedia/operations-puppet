# == Class druid::bigtop::hadoop::user
#
# Ensures that the druid user/group exist.
#
class druid::bigtop::hadoop::user {

    if debian::codename::ge('buster') {
        $druid_uid = 907
        $druid_gid = 907
    } else {
        $druid_uid = undef
        $druid_gid = undef
    }

    group { 'druid':
        ensure => 'present',
        system => true,
        gid    => $druid_gid,
    }
    user { 'druid':
        ensure     => 'present',
        uid        => $druid_uid,
        gid        => 'druid',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
        require    => Group['druid'],
    }
}
