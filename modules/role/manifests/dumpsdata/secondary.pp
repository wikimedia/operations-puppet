class role::dumpsdata::secondary {
    system::role { 'dumpsdatasecondary': description => 'Fallback NFS server of dumps data to dumps producer hosts' }

    include ::standard
    include ::profile::dumpsdata_secondary
}
