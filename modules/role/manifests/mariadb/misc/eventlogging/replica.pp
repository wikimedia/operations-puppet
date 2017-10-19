class role::mariadb::misc::eventlogging::replica {
    include ::profile::mariadb::misc::eventlogging::database
    include ::profile::mariadb::misc::eventlogging::replication
}