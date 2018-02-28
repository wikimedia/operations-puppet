class labstore::monitoring::exports(
    $contact_groups='wmcs-team,admins',
    ) {

    nrpe::monitor_systemd_unit_state { 'nfs-exportd':
        description   => 'Ensure NFS exports are maintained for new instances with NFS',
        contact_group => $contact_groups,
    }
}
