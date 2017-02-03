# filtertags: labs-project-tools
class role::toollabs::checker {
    include ::toollabs::checker

    system::role { 'role::toollabs::checker':
        description => 'Exposes end points for external monitoring of internal systems',
    }
}
