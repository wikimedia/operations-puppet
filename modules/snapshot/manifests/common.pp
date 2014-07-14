class snapshot::common {
    include standard

    include nfs::data
    include snapshot::packages
    include snapshot::sync
}
