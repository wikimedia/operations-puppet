# This profile sets up a grid shadow master in the Toolforge model.

class profile::toolforge::grid::shadow{
    include profile::openstack::main::clientpackages
    include profile::openstack::main::observerenv
    include profile::toolforge::infrastructure

    class { '::sonofgridengine::shadow_master':
        sgeroot    => $profile::toolforge::grid::base::geconf,
    }
}
