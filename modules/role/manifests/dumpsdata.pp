class role::dumpsdata {
    system::role { 'dumpsdata': description => 'NFS server of dumps data to dumps producer hosts' }

    include ::standard
    include ::profile::dumpsdata
}
