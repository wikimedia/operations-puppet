class role::backup {
    include profile::base::production

    # We actually want to be able to backup ourselves
    include profile::backup::host
    include profile::backup::filesets

    include profile::backup::director
    # Directors are also storage nodes for es dbs
    include profile::backup::storage::es
}
