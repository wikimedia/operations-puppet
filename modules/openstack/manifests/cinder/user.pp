class openstack::cinder::user (
) {
    # The cinder packages create this user, but with a weird, non-system ID.
    # Instead, create the user ahead of time with a proper uid.

    systemd::sysuser { 'cinder':
        description => 'cinder system user',
    }
}
