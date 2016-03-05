# = Class: role::programdashboard::database
#
# This role sets up a database server for the Program Dashboard Rails
# application.
#
class role::programdashboard::database {
    include ::programdashboard::database

    system::role { 'role::programdashboard::database':
        description => 'Program Dashboard database server',
    }
}
