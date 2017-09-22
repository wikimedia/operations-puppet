class role::dumps::public::server {
    system::role { 'dumps::public::server': description => 'labstore host in the public VLAN that serves Dumps to clients via NFS/Web/Rsync' }

    include ::standard

    include ::profile::dumps::public_server
}
