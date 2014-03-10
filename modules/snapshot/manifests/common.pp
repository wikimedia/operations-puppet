class snapshot::common {
    include base
    include ntp::client
    include ganglia

    include nfs::data
    include snapshot::packages
    include snapshot::sync
    include snapshot::phpfiles
}
