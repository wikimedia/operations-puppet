class role::wmcs::toolforge::harbor::db {
    include profile::toolforge::base
    include profile::toolforge::infrastructure
    include profile::toolforge::harbor::db
    system::role { "${name} (postgres ${profile::toolforge::harbor::db::db_role})":
        description => 'Harbor Repo Database Server',
    }
}
