class role::labs::shinken {
    system::role { $name: }

    include ::profile::wmcs::shinken
}
