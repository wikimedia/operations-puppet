class mariadb {

    include mariadb::user
    include mariadb::config
    include mariadb::sources
    include mariadb::packages
    include mariadb::datadir
}