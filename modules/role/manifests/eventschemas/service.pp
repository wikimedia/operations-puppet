# Class: role::eventschemas::service
#
class role::eventschemas::service {
    system::role { 'eventschemas::service':
        description => 'HTTP Service for event schemas'
    }

    include ::profile::eventschemas::service
}
