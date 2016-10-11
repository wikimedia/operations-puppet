# Annoy Sean
class role::mariadb::monitor::dba {

    include mariadb::monitor_disk
    include mariadb::monitor_process
}

