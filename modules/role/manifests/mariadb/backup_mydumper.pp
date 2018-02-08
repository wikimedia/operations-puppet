class role::mariadb::backup_mydumper {
    include profile::backup::host
    include profile::mariadb::backup::mydumper
    include profile::mariadb::backup::bacula
}
