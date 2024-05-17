class role::backup::offsite {
    include profile::base::production
    include profile::backup::storage::main
}
