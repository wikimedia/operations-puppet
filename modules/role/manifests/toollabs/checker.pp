# filtertags: labs-project-tools
class role::toollabs::checker {
    require ::profile::openstack::eqiad1::clientpackages::vms

    system::role { 'toollabs::checker':
        description => 'Exposes end points for external monitoring of internal systems',
    }
    include ::toollabs::checker
}
