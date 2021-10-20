# Beta Cluster DB server
#
class role::mariadb::beta {

    system::role { 'mariadb::beta':
        description => 'beta cluster database server',
    }

    include profile::mariadb::beta
}
