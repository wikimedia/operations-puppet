# filtertags: labs-project-tools
class role::toollabs::redis {
    system::role {
        'role::toollabs::redis':
        description => 'Server that hosts shared Redis instance',
    }

    include ::toollabs::redis
}
