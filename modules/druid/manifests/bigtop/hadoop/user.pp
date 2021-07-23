# == Class druid::bigtop::hadoop::user
#
# Ensures that the druid user/group exist.
#
class druid::bigtop::hadoop::user {

    # From Buster onward, we want to have fixed uid/gids for daemons.
    # We manage service system users in puppet classes, but declare
    # commented placeholders for them in the admin module's data.yaml file
    # to ensure that people don't accidentally add uid/gid conflicts.
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
