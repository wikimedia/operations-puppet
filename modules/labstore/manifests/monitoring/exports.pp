class labstore::monitoring::exports(
    String $contact_groups='wmcs-team-email,admins',
    String $drbd_role='primary',
){
    # This really doesn't need to be running on the secondary.
    if $drbd_role == 'primary' {
        nrpe::monitor_systemd_unit_state { 'nfs-exportd':
            description   => 'Ensure NFS exports are maintained for new instances with NFS',
            contact_group => $contact_groups,
        }
    } else {
        # When switching roles, this may cause some alert noise, so please downtime.
        nrpe::monitor_systemd_unit_state { 'nfs-exportd':
            ensure        => absent,
            description   => 'Ensure NFS exports are maintained for new instances with NFS',
            contact_group => $contact_groups,
        }
    }
}
