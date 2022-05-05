#TODO: remove this file after all hosts have been switched to use
#the new role::wmcs::db::toolsdb
class role::wmcs::db::toolsdb_secondary {

    system::role { $name:
        description => 'Cloud user database secondary',
    }

    include ::profile::mariadb::monitor
    include ::profile::wmcs::services::toolsdb
}
