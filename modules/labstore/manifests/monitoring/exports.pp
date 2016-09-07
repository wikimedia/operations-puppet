class labstore::monitoring::exports {

    nrpe::monitor_systemd_unit_state { 'nfs-exportd':
        description => 'Ensure NFS exports are maintained for new instances with NFS',
    }
}
