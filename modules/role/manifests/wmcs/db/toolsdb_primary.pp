#TODO: remove this file after all hosts have been switched to use
#the new role::wmcs::db::toolsdb
class role::wmcs::db::toolsdb_primary {
    system::role { $name: }

    include ::profile::mariadb::monitor
    include ::profile::wmcs::services::toolsdb
}
