class role::backup {
    # We actually want to be able to backup ourselves
    include profile::backup::host
    include profile::backup::director
    include profile::backup::filesets
    include profile::backup::storage::main
    include profile::base::production
}
