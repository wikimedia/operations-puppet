# filtertags: labs-project-tools
class role::toollabs::checker {
    require ::profile::openstack::main::clientlib

    system::role { 'toollabs::checker':
        description => 'Exposes end points for external monitoring of internal systems',
    }
    include ::toollabs::checker
}
