class role::dumps::public::server {
    system::role { 'dumps::public::server': description => 'Dumps host in public VLAN that serves dumps to clients via NFS/Web/Rsync' }

    include ::standard
}
