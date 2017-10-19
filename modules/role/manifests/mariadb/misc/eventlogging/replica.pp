class role::mariadb::misc::eventlogging::replica {
    include ::standard
    include ::base::firewall
    include ::profile::mariadb::misc::eventlogging::database
    include ::profile::mariadb::misc::eventlogging::replication
}