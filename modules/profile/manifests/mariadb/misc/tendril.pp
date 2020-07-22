# tendril.wikimedia.org db
class profile::mariadb::misc::tendril {
    require_package('libodbc1') # hack to fix CONNECT dependency

    profile::mariadb::section { 'tendril': }

    # Firewall rules for the tendril db hosts so they can be accessed
    # by tendril and dbtree web server (on a public ip)
    ferm::service { 'tendril-backend':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '@resolve((dbmonitor1001.wikimedia.org dbmonitor2001.wikimedia.org))',
    }
}
