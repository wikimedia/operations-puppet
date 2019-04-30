# Class: role::eventschemas::service
#
class role::eventschemas::service {
    system::role { 'eventschemas::service':
        description => 'HTTP Service for event schemas'
    }
    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::eventschemas::service
    include ::profile::lvs::realserver
}
