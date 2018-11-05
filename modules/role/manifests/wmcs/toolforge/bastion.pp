# filtertags: labs-project-tools
class role::wmcs::toolforge::bastion {
    system::role { 'wmcs::toolforge::bastion': description => 'Toolforge bastion' }

    include profile::toolforge::apt_pinning
    include profile::toolforge::grid::base
    include profile::toolforge::bastion
}
