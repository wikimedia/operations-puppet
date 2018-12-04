class role::wmcs::toolforge::clush::master {
    system::role { $name:
        description => 'Toolforge clush master server'
    }

    include profile::toolforge::base
    include profile::toolforge::infrastructure
    include profile::toolforge::clush::master
}
