# == Class mariadb
#
class mariadb {

    include mariadb::config
    include mariadb::packages
    include mariadb::monitor_disk
    include mariadb::monitor_process
}
