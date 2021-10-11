class openstack::cinder::user (
) {
    # The cinder packages create this user, but with a weird, non-system ID.
    # Instead, create the user ahead of time with a proper uid.
    group { 'cinder':
        ensure => 'present',
        name   => 'cinder',
        system => true,
    }

    user { 'cinder':
        ensure     => 'present',
        name       => 'cinder',
        comment    => 'cinder system user',
        gid        => 'cinder',
        managehome => true,
        system     => true,
    }
}
