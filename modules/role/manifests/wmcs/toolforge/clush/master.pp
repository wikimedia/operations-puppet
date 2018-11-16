class role::wmcs::toolforge::clush::master {
    system::role { $name: }

    include profile::toolforge::base
    include profile::toolforge::infrastructure
    include profile::toolforge::clush::master
}
