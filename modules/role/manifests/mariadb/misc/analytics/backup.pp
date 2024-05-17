class role::mariadb::misc::analytics::backup {
    include profile::base::production
    include profile::firewall

    include profile::mariadb::misc::analytics::multiinstance
}
