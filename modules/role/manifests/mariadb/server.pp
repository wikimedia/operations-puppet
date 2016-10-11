# Generic Server
class role::mariadb::server {

    system::role { 'role::mariadb::server':
        description => 'database server',
    }

    include standard
    include ::mariadb
}

