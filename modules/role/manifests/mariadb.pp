# Generic Server
#
class role::mariadb {

    system::role { 'mariadb':
        description => 'database server',
    }

    include ::profile::base::production
    include ::mariadb
}
