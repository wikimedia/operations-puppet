class role::backup {
    include profile::base::production

    # We actually want to be able to backup ourselves
    include profile::backup::host
    include profile::backup::filesets

    include profile::backup::director
    # future storage daemon could go here
}
