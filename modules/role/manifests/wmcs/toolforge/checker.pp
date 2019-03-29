# filtertags: labs-project-tools
class role::wmcs::toolforge::checker {
    system::role { $name:
        description => 'Toolforge checker'
    }

    include profile::toolforge::base
    include profile::toolforge::apt_pinning
    include profile::toolforge::checker
}
