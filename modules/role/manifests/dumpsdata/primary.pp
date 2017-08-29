class role::dumpsdata::primary {
    system::role { 'dumpsdataprimary': description => 'Active NFS server of dumps data to dumps producer hosts' }

    include ::standard
    include ::profile::dumpsdata::primary
}
