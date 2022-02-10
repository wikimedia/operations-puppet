# tendril.wikimedia.org db
class profile::mariadb::misc::tendril {
    ensure_packages('libodbc1') # hack to fix CONNECT dependency

    profile::mariadb::section { 'tendril': }

    # Firewall rules for the tendril db hosts so they can be accessed
    # by tendril, dbtree and orchestrator web servers (on public ips)
    ferm::service { 'tendril-backend':
        ensure  => absent,
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
    }
}
