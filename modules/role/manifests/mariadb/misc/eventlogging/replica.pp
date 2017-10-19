class role::mariadb::misc::eventlogging::replica() {
    include ::profile::mariadb::eventlogging::database
    include ::profile::mariadb::eventlogging::replication
}