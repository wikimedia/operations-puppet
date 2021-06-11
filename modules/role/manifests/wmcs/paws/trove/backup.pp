class role::wmcs::paws::trove::backup {
    system::role { $name: }

    include profile::wmcs::paws::common
    include profile::wmcs::paws::trove::backup
}
