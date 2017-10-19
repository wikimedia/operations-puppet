class role::mariadb::misc::eventlogging::master {
    include ::standard
    include ::base::firewall
    include ::profile::mariadb::misc::eventlogging::database
}