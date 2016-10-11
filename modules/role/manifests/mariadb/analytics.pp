# MariaDB 10 Analytics all-shards slave, with scratch space and TokuDB
# analytics slaves are already either dbstores or eventlogging slaves
# so they just need the extra core monitoring
class role::mariadb::analytics {
    mariadb::monitor_replication { ['s1','s2']:
        is_critical   => false,
        contact_group => 'admins', # only show on nagios/irc
        multisource   => true,
    }
}

