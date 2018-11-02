# filtertags: labs-project-tools
class role::wmcs::toolforge::bastion {

    include profile::toolforge::grid::base
    include profile::toolforge::bastion

    system::role { 'wmcs::toolforge::bastion': description => 'Toolforge bastion' }
}
