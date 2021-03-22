# tendril.wikimedia.org db
class profile::mariadb::misc::tendril {
    require_package('libodbc1') # hack to fix CONNECT dependency

    profile::mariadb::section { 'tendril': }

    # Firewall rules for the tendril db hosts so they can be accessed
    # by tendril, dbtree and orchestrator web servers (on public ips)
    ferm::service { 'tendril-backend':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '@resolve((dbmonitor1001.wikimedia.org dbmonitor1002.wikimedia.org dborch1001.wikimedia.org))',
    }
}
