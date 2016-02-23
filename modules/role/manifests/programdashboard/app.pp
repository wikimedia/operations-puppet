# = Class: role::programdashboard::app
#
# This role sets up Program Dashboard dependencies and an Apache/Passenger
# configuration for running the Rails application.
#
class role::programdashboard::app {
    include ::programdashboard::app

    system::role { 'role::programdashboard::app':
        description => 'Program Dashboard application server',
    }
}
