class mariadb {

    include mariadb::config
    include mariadb::packages
    include mariadb::datadir
}