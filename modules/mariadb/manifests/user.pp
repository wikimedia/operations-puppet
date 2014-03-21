class mariadb::user {

    generic::systemuser { 'mysql':
        name  => 'mysql',
        shell => '/bin/sh',
        home  => '/home/mysql',
    }
}